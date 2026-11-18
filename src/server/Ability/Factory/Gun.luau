--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local GunFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Gun")
local ShotFactory = require("@game/ServerScriptService/Server/Ability/Factory/Shot")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the server half of a gun ability: a shot like any other, taken with a weapon everybody else gets to see
Module.new = function(ability: GunFactory.Ability): AbilityBuilder.ServerBuilder
	local bindings = ability.Layout.Bindings
	local builder = ShotFactory.new(ability.Shot)

	-- the player's own machine shows them what they hold right away, this is for everybody else
	for _, prop in ability.Config.Props do
		builder = builder:RunClient(
			bindings.Hold,
			ClientVFXDefinition.Prop,
			function(context: ServerContext): ClientVFXType.Prop
				return GunFactory.getProp(ability.Config, prop, context.Color)
			end,
			{ Audience = "Others" }
		)
	end

	return builder
end

return Module
