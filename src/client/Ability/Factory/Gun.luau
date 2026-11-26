--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local GunFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Gun")
local ShotFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Shot")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ClientContext = AbilityType.ClientContext
type AnimationKey = VFXAssetDefinition.AnimationKey
-- what only the player who shoots needs to know
export type Config = {
	HoldAnimation: AnimationKey, -- for as long as the weapon is out
	CastAnimation: AnimationKey?, -- from the click on, the shot leaves part-way through it. none without
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the client half of a gun ability: a shot like any other, taken with a weapon the player sees in their hands the
-- moment they get it out
Module.new = function(ability: GunFactory.Ability, config: Config): AbilityBuilder.ClientBuilder
	local bindings = ability.Layout.Bindings
	local builder = ShotFactory.new(ability.Shot, { CastAnimation = config.CastAnimation })
		:Run(bindings.Hold, ClientVFXDefinition.Animation, function(): ClientVFXType.Animation
			return { Animation = config.HoldAnimation }
		end)

	for _, prop in ability.Config.Props do
		builder = builder:Run(
			bindings.Hold,
			ClientVFXDefinition.Prop,
			function(context: ClientContext): ClientVFXType.Prop
				return GunFactory.getProp(ability.Config, prop, context.Color)
			end
		)
	end

	return builder
end

return Module
