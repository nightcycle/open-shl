--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerScope = VFXType.ServerScope
export type Properties = {
	Amount: number,
}
-- Constants
local isProperties = Type.strictInterface({
	Amount = Type.numberMin(0),
})
local MAX_HEALTH = AttributeDefinition.MAX_HEALTH
-- Variables
-- References
-- Private Functions
-- Class
-- gives the character the effect belongs to health back, once + for nothing, up to what a character has at most. true
-- if it was theirs to get: nothing brings back who's already down
return ServerVFX.newEvent("Heal", isProperties, function(props: Properties, scope: ServerScope): boolean
	local character = scope.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if
		not character
		or not humanoid
		or humanoid.Health <= 0
		or AttributeDefinition.get(character, AttributeDefinition.IsDead)
	then
		return false
	end
	local health = math.min(MAX_HEALTH, AttributeDefinition.get(character, AttributeDefinition.Health) + props.Amount)
	AttributeDefinition.set(character, AttributeDefinition.Health, health)
	return true
end)
