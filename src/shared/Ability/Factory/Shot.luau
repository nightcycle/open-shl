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
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type EventBinding = AbilityType.EventBinding
type ClientSignal<T> = AbilityType.ClientSignal<T>
type Layout<B> = AbilityType.Layout<B>
-- where the client let a shot fly, so it takes the same path on every machine
export type Launch = {
	Id: number, -- the client's own count of its shots, what it ran into is told by it
	Origin: Vector3,
	Direction: Vector3, -- of length 1
}
-- what the client saw one of its shots run into
export type Hit = {
	ShotId: number,
	Target: Model,
}
-- where the client saw one of its shots run into anything at all
export type Land = {
	ShotId: number,
	Position: Vector3,
}
export type Bindings = {
	Cast: EventBinding,
	Release: EventBinding, -- the wind-up is over, the shot leaves
	Abort: EventBinding?, -- one that's charged was let go of too soon, nothing leaves
	Launch: ClientSignal<Launch>,
	Hit: ClientSignal<Hit>,
	Land: ClientSignal<Land>?, -- only one with a landing has it
	Recover: EventBinding,
}
-- what both halves of a shot ability have to agree on
export type Config = {
	ReleaseDelay: number, -- seconds from the click until the shot leaves
	Duration: number, -- seconds from the click until the next one counts
	Limb: string, -- the name of the part of the avatar the shot leaves from
	Offset: Vector3?, -- of the spot on the limb it leaves from off the middle of it, in the space of the limb
	Speed: number, -- studs a second
	Lifetime: number, -- seconds the shot flies for at most
	Gravity: number?, -- studs a second it picks up downwards every second, it flies straight without
	Size: Vector3,
	Color: Color3, -- the one it has unless the character picked one
	FireSize: number?, -- of the flame it trails, none without
	FireHeat: number?, -- how fast its flame rises, as fast as one that trails a shot without
	SecondaryColor: Color3?, -- of the sparks of its flame, the color of the rest of it without
	HasSparkles: boolean?, -- it trails sparkles
	Particles: { VFXAssetDefinition.ParticleKey }?, -- what it gives off on its way
	Material: Enum.Material?, -- it glows without
	Mesh: VFXAssetDefinition.MeshKey?,
	MeshScale: Vector3?,
	-- how it's turned off the way it flies. without: a flame trails behind it, anything else points ahead
	Turn: CFrame?,
	IsSticking: boolean?, -- it's left where it ran into something for as long as it had left to fly
	IsHidden: boolean?, -- nobody gets to see it fly: it still runs into whoever is in its way
	-- it leaves as the button is let go of, once that was held for as long as the release takes. by itself without
	IsCharged: boolean?,
	HasLanding: boolean?, -- where it ran into something is told + the server makes something of it
	IsReturning: boolean?, -- at the end of its way it flies back to the limb it left
	LaunchSound: VFXAssetDefinition.SoundKey?, -- heard as it leaves
	LandSound: VFXAssetDefinition.SoundKey?, -- heard from wherever it runs into something
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
-- a shot is out for longer than its cast takes: word of it comes in whatever the machine is up to by then
local STATE_IDS = table.freeze({ "Idle", "Casting", "Recovering" })
-- how far off 1 the length of a direction may be, a remote doesn't hand a vector on bit for bit
local DIRECTION_TOLERANCE = 0.01
local isDirection = function(value: unknown): (boolean, string?)
	local success, msg = AbilityType.FiniteVector3(value)
	if not success then
		return false, msg
	end
	local length = (value :: Vector3).Magnitude
	if math.abs(length - 1) > DIRECTION_TOLERANCE then
		return false, `a direction of length 1 expected, got one of {length}`
	end
	return true
end
local isLaunch = Type.strictInterface({
	Id = Type.integer,
	Origin = AbilityType.FiniteVector3,
	Direction = isDirection,
})
local isHit = Type.strictInterface({
	ShotId = Type.integer,
	Target = Type.instanceIsA("Model"),
})
local isLand = Type.strictInterface({
	ShotId = Type.integer,
	Position = AbilityType.FiniteVector3,
})
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- every state the machine of a shot gets to, for a factory that puts bindings of its own next to the ones below
Module.STATE_IDS = STATE_IDS

-- what word of a shot has to be, for an ability that lets shots fly without the bindings below
Module.Launch = isLaunch
Module.Hit = isHit

-- the bindings of an ability that lets something fly: a click with the tool out winds it up, the shot leaves once
-- that's done + whoever it runs into first is hit. the tool can be put away mid-cast, the shot still leaves
Module.newBindings = function(id: string, config: Config): Bindings
	-- the landing of one that's pulled down would have to be held to its arc, nothing asks for that yet
	assert(not (config.HasLanding and config.Gravity), `"{id}" has a landing, it can't be pulled down as well`)
	assert(not (config.IsReturning and config.IsHidden), `"{id}" comes back, it can't be hidden as well`)
	local release = AbilityTrigger.after(config.ReleaseDelay)
	local abort: EventBinding? = nil
	if config.IsCharged then
		-- held for long enough it leaves as the button is let go of, let go of any sooner it never does
		local wound = AbilityCondition.elapsed(config.ReleaseDelay)
		local letGo = AbilityTrigger.stopped(AbilityCondition.PRIMARY)
		release = AbilityTrigger.during(letGo, AbilityTrigger.active(wound))
		abort = VFXBinding.event(
			{ "Casting" },
			AbilityTrigger.during(letGo, AbilityTrigger.inactive(wound)),
			{ To = "Idle" }
		)
	end
	return {
		Cast = VFXBinding.event(
			{ "Idle" },
			AbilityTrigger.during(
				AbilityTrigger.started(AbilityCondition.PRIMARY),
				AbilityTrigger.active(AbilityCondition.equipped(id))
			),
			{ To = "Casting" }
		),
		Release = VFXBinding.event({ "Casting" }, release, { To = "Recovering" }),
		Abort = abort,
		Launch = VFXBinding.signal(STATE_IDS, "Client", isLaunch) :: ClientSignal<Launch>,
		Hit = VFXBinding.signal(STATE_IDS, "Client", isHit) :: ClientSignal<Hit>,
		Land = if config.HasLanding then VFXBinding.signal(STATE_IDS, "Client", isLand) :: ClientSignal<Land> else nil,
		Recover = VFXBinding.event(
			{ "Recovering" },
			AbilityTrigger.after(config.Duration - config.ReleaseDelay),
			{ To = "Idle" }
		),
	}
end

Module.new = function(id: string, config: Config): Ability
	return table.freeze({
		Layout = VFXBinding.layout(id, "Idle", true, Module.newBindings(id, config)),
		Config = table.freeze(table.clone(config)),
	})
end

-- the shot as every machine shows it: on the path the client let it fly on, in the color its character wears
Module.getBolt = function(config: Config, launch: Launch, color: Color3?): ClientVFXType.Bolt
	return {
		Origin = launch.Origin,
		Direction = launch.Direction,
		Speed = config.Speed,
		Lifetime = config.Lifetime,
		Size = config.Size,
		Color = color or config.Color,
		FireSize = config.FireSize,
		FireHeat = config.FireHeat,
		SecondaryColor = config.SecondaryColor,
		HasSparkles = config.HasSparkles,
		Particles = config.Particles,
		Material = config.Material,
		Mesh = config.Mesh,
		MeshScale = config.MeshScale,
		Turn = config.Turn,
		Gravity = config.Gravity,
		IsSticking = config.IsSticking,
		ReturnLimb = if config.IsReturning then config.Limb else nil,
		LandSound = config.LandSound,
	}
end

return Module
