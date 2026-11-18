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
type StateBinding = AbilityType.StateBinding
type ClientSignal<T> = AbilityType.ClientSignal<T>
type Layout<B> = AbilityType.Layout<B>
type SoundKey = VFXAssetDefinition.SoundKey
type Prop = ClientVFXType.Prop
-- what the client saw its weapon run into
export type Hit = {
	Target: Model,
}
export type Bindings = {
	Hold: StateBinding, -- the weapon is out
	Draw: EventBinding,
	Sheathe: EventBinding,
	Swing: EventBinding,
	Sweep: StateBinding, -- the weapon is on its way through the air
	Hit: ClientSignal<Hit>,
	Recover: EventBinding,
}
-- a box that's swept through the air by the limb that carries it: around what the limb holds, or the limb itself
export type Hitbox = {
	Limb: string, -- the name of the part of the avatar
	Size: Vector3,
	Offset: CFrame, -- of the box from the limb
}
-- what both halves of a melee ability have to agree on
export type Config = {
	Duration: number, -- seconds from the start of a swing until the next one
	Reach: number, -- studs from the middle of the avatar a swing gets to at most
	-- what's held for as long as the weapon is out, each in the color it has unless the character picked one. bare
	-- hands hold nothing
	Props: { Prop },
	Hitboxes: { Hitbox }, -- all of them are on with every swing, whoever any of them runs into is hit once
	DrawSound: SoundKey?,
	SheatheSound: SoundKey?,
	SwingSound: SoundKey?,
	-- seconds into the draw the weapon is in the hand, it's seen + heard from then on. at once without
	DrawDelay: number?,
	SheatheDelay: number?, -- seconds the weapon stays in the hand once it's put away, none without
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
local isHit = Type.strictInterface({
	Target = Type.instanceIsA("Model"),
})
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the bindings of an ability that swings something held in the hand: it comes out with the tool, a click swings it +
-- whoever it runs into on the way is hit once
Module.new = function(id: string, config: Config): Ability
	local equipped = AbilityCondition.equipped(id)
	local bindings: Bindings = {
		Hold = VFXBinding.state({ "Idle", "Swinging" }, AbilityTrigger.active(equipped)),
		Draw = VFXBinding.event({ "Idle" }, AbilityTrigger.started(equipped)),
		Sheathe = VFXBinding.event({ "Idle", "Swinging" }, AbilityTrigger.stopped(equipped), { To = "Idle" }),
		Swing = VFXBinding.event(
			{ "Idle" },
			AbilityTrigger.during(AbilityTrigger.started(AbilityCondition.PRIMARY), AbilityTrigger.active(equipped)),
			{ To = "Swinging" }
		),
		Sweep = VFXBinding.state({ "Swinging" }, AbilityTrigger.always()),
		Hit = VFXBinding.signal({ "Swinging" }, "Client", isHit) :: ClientSignal<Hit>,
		Recover = VFXBinding.event({ "Swinging" }, AbilityTrigger.after(config.Duration), { To = "Idle" }),
	}
	local out: Config = table.clone(config)
	local props: { Prop } = {}
	for _, prop in config.Props do
		local timedProp = table.clone(prop)
		timedProp.Delay = config.DrawDelay
		timedProp.Linger = config.SheatheDelay
		table.insert(props, table.freeze(timedProp))
	end
	out.Props = table.freeze(props)
	out.Hitboxes = table.freeze(table.clone(config.Hitboxes))
	return table.freeze({
		Layout = VFXBinding.layout(id, "Idle", true, bindings),
		Config = table.freeze(out),
	})
end

-- one of the props as every machine shows it: in the color the character wears the ability in
Module.getProp = function(prop: Prop, color: Color3?): Prop
	local out = table.clone(prop)
	out.Color = color or prop.Color
	return out
end

-- what's heard at which binding, for the ones the ability has a sound for. the draw is heard as the weapon shows
Module.getSounds = function(ability: Ability): { [EventBinding]: ClientVFXType.Sound }
	local bindings = ability.Layout.Bindings
	local config = ability.Config
	local sounds: { [EventBinding]: ClientVFXType.Sound } = {}
	if config.DrawSound then
		sounds[bindings.Draw] = table.freeze({ Sound = config.DrawSound, Delay = config.DrawDelay })
	end
	if config.SheatheSound then
		sounds[bindings.Sheathe] = table.freeze({ Sound = config.SheatheSound })
	end
	if config.SwingSound then
		sounds[bindings.Swing] = table.freeze({ Sound = config.SwingSound })
	end
	return sounds
end

return Module
