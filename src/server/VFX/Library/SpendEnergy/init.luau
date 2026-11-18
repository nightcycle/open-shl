--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerScope = VFXType.ServerScope
export type Properties = {
	Amount: number,
	IsQuiet: boolean?, -- nobody is warned if there isn't enough
}
-- Constants
local isProperties = Type.strictInterface({
	Amount = Type.numberMin(0),
	IsQuiet = Type.optional(Type.boolean),
})
-- Variables
-- References
-- Private Functions
-- Class
-- takes energy off the character the effect belongs to. false if there isn't enough of it: nothing is taken + their
-- player is warned, unless it's asked to keep quiet
return ServerVFX.newEvent("SpendEnergy", isProperties, function(props: Properties, scope: ServerScope): boolean
	local character = scope.Character
	if not character then
		return false
	end
	if not ModeDefinition.getIfEnergyEnabled() then
		return true
	end
	local energy = AttributeDefinition.get(character, AttributeDefinition.Energy)
	if energy < props.Amount then
		if not props.IsQuiet then
			scope.fireClient(ClientVFXDefinition.EnergyWarning, {}, { Audience = "Owner" })
		end
		return false
	end
	AttributeDefinition.set(character, AttributeDefinition.Energy, energy - props.Amount)
	return true
end)
