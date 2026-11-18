--!strict
-- Services
-- Packages
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local ShotFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Shot")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
type ClientSignal<T> = AbilityType.ClientSignal<T>
type Layout<B> = AbilityType.Layout<B>
type Prop = ClientVFXType.Prop
export type Bindings = {
	Hold: StateBinding, -- the weapon is out
	Cast: EventBinding,
	Release: EventBinding,
	Launch: ClientSignal<ShotFactory.Launch>,
	Hit: ClientSignal<ShotFactory.Hit>,
	Recover: EventBinding,
}
-- what both halves of a gun ability have to agree on
export type Config = {
	Shot: ShotFactory.Config, -- everything about what it shoots
	Props: { Prop }, -- what's held for as long as the weapon is out
	-- the color the character picked is worn by the weapon as well, only by what it shoots without
	HasColoredProps: boolean?,
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
	-- the same ability the way the shot factory takes one: all it doesn't know of is the hold
	Shot: ShotFactory.Ability,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the bindings of an ability that shoots with something held in the hand: the weapon comes out with the tool, from
-- there on it's a shot like any other
Module.new = function(id: string, config: Config): Ability
	local shot = ShotFactory.newBindings(id, config.Shot)
	local bindings: Bindings = {
		Hold = VFXBinding.state(ShotFactory.STATE_IDS, AbilityTrigger.active(AbilityCondition.equipped(id))),
		Cast = shot.Cast,
		Release = shot.Release,
		Launch = shot.Launch,
		Hit = shot.Hit,
		Recover = shot.Recover,
	}
	local layout = VFXBinding.layout(id, "Idle", true, bindings)
	local shotConfig = table.freeze(table.clone(config.Shot))
	return table.freeze({
		Layout = layout,
		Config = table.freeze({
			Shot = shotConfig,
			Props = table.freeze(table.clone(config.Props)),
			HasColoredProps = config.HasColoredProps,
		}),
		Shot = table.freeze({
			-- a layout is one table of bindings, typed by whoever made it
			Layout = layout :: any,
			Config = shotConfig,
		}),
	})
end

-- one of the props as every machine shows it: in the color the character wears the ability in, if that's the
-- weapon's to wear
Module.getProp = function(config: Config, prop: Prop, color: Color3?): Prop
	local out = table.clone(prop)
	out.Color = if config.HasColoredProps and color then color else prop.Color
	return out
end

return Module
