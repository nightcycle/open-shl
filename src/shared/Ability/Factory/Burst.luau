--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
type ClientSignal<T> = AbilityType.ClientSignal<T>
type Layout<B> = AbilityType.Layout<B>
type SoundKey = VFXAssetDefinition.SoundKey
-- who the client saw its move get to
export type Hit = {
	Target: Model,
}
export type Bindings = {
	Hold: StateBinding, -- the tool is out
	Cast: EventBinding,
	Brace: StateBinding, -- the avatar is held where it stands
	Release: EventBinding, -- the wind-up is over, the move goes off
	Surge: StateBinding, -- it's going off
	Subside: EventBinding, -- it's done going off
	Hit: ClientSignal<Hit>,
	Recover: EventBinding, -- the next click counts again
	Settle: EventBinding, -- the avatar is let go of
}
-- a box that leaves the avatar the way it faces as the move goes off, whoever it runs into is hit
export type Front = {
	Limb: string, -- the name of the part of the avatar it leaves from
	Size: Vector3,
	Speed: number, -- studs a second
	Lifetime: number, -- seconds it's on its way for
}
-- what both halves of a burst ability have to agree on
export type Config = {
	ReleaseDelay: number, -- seconds from the click until it goes off
	SurgeDuration: number, -- seconds it keeps going off for, over before the next click counts
	Duration: number, -- seconds from the click until the next one counts
	RootDuration: number, -- seconds from the click the avatar is held where it stands for, the duration at least
	Reach: number, -- studs from the middle of the avatar it gets to at most
	HitDelay: number, -- seconds from the click until it can get to anybody
	HitDuration: number, -- seconds it can keep getting to them for from there
	-- seconds from a hit until the next one counts, whoever it's on. without: everybody is hit once with every cast
	HitInterval: number?,
	Front: Front?, -- nothing leaves the avatar without
	CastSound: SoundKey?,
	ReleaseSound: SoundKey?,
	SubsideSound: SoundKey?,
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
-- what a move let go of is still out there once the cast is over: word of who it got to comes in whatever the
-- machine is up to by then
local STATE_IDS = table.freeze({ "Idle", "Casting", "Settling" })
local isHit = Type.strictInterface({
	Target = Type.instanceIsA("Model"),
})
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the bindings of an ability that lets something go off the avatar: a click with the tool out winds it up with the
-- avatar held where it stands, it goes off once that's done + whoever it gets to within its reach is hit. the tool
-- can be put away mid-cast, the move still goes off. one that holds the avatar for longer than its cast takes can be
-- cast again while it still does
Module.new = function(id: string, config: Config): Ability
	local subsideDelay = config.ReleaseDelay + config.SurgeDuration
	assert(subsideDelay <= config.Duration, `"{id}" is still going off by the time the next click counts`)
	assert(config.RootDuration >= config.Duration, `"{id}" lets go of the avatar before its cast is over`)
	local equipped = AbilityCondition.equipped(id)
	local bindings: Bindings = {
		Hold = VFXBinding.state(STATE_IDS, AbilityTrigger.active(equipped)),
		Cast = VFXBinding.event(
			{ "Idle", "Settling" },
			AbilityTrigger.during(AbilityTrigger.started(AbilityCondition.PRIMARY), AbilityTrigger.active(equipped)),
			{ To = "Casting" }
		),
		Brace = VFXBinding.state({ "Casting", "Settling" }, AbilityTrigger.always()),
		Release = VFXBinding.event({ "Casting" }, AbilityTrigger.after(config.ReleaseDelay)),
		Surge = VFXBinding.state(
			{ "Casting" },
			AbilityTrigger.all(
				AbilityTrigger.active(AbilityCondition.elapsed(config.ReleaseDelay)),
				AbilityTrigger.inactive(AbilityCondition.elapsed(subsideDelay))
			)
		),
		Subside = VFXBinding.event({ "Casting" }, AbilityTrigger.after(subsideDelay)),
		Hit = VFXBinding.signal(STATE_IDS, "Client", isHit) :: ClientSignal<Hit>,
		Recover = VFXBinding.event(
			{ "Casting" },
			AbilityTrigger.after(config.Duration),
			{ To = if config.RootDuration > config.Duration then "Settling" else "Idle" }
		),
		Settle = VFXBinding.event(
			{ "Settling" },
			AbilityTrigger.after(config.RootDuration - config.Duration),
			{ To = "Idle" }
		),
	}
	return table.freeze({
		Layout = VFXBinding.layout(id, "Idle", true, bindings),
		Config = table.freeze(table.clone(config)),
	})
end

-- what's heard at which binding, for the ones the ability has a sound for
Module.getSounds = function(ability: Ability): { [EventBinding]: SoundKey }
	local bindings = ability.Layout.Bindings
	local config = ability.Config
	local sounds: { [EventBinding]: SoundKey } = {}
	if config.CastSound then
		sounds[bindings.Cast] = config.CastSound
	end
	if config.ReleaseSound then
		sounds[bindings.Release] = config.ReleaseSound
	end
	if config.SubsideSound then
		sounds[bindings.Subside] = config.SubsideSound
	end
	return sounds
end

-- where a front sets out from on the machine that asks: at the limb, turned the way the avatar faces. nil for an
-- avatar that's missing the limb
Module.getFrontCFrame = function(character: Model, front: Front): CFrame?
	local limb = character:FindFirstChild(front.Limb)
	if not limb or not limb:IsA("BasePart") then
		return nil
	end
	return CFrame.lookAt(limb.Position, limb.Position + character:GetPivot().LookVector)
end

return Module
