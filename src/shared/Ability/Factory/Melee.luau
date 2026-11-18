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
-- what both halves of a melee ability have to agree on
export type Config = {
	Duration: number, -- seconds from the start of a swing until the next one
	Reach: number, -- studs from the middle of the avatar a swing gets to at most
	Prop: ClientVFXType.Prop, -- the weapon, in the color it has unless the character picked one
	-- the box around the weapon that's swept through the air, carried by the limb that holds it
	HitboxSize: Vector3,
	HitboxOffset: CFrame,
	SwingSound: VFXAssetDefinition.SoundKey?,
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
	return table.freeze({
		Layout = VFXBinding.layout(id, "Idle", true, bindings),
		Config = table.freeze(table.clone(config)),
	})
end

return Module
