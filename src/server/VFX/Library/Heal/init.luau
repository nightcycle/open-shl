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
	Target: Model?, -- who gets it, the character the effect belongs to without
}
-- Constants
local isProperties = Type.strictInterface({
	Amount = Type.numberMin(0),
	Target = Type.optional(Type.instanceIsA("Model")),
})
local MAX_HEALTH = AttributeDefinition.MAX_HEALTH
-- Variables
-- References
-- Private Functions
-- Class
-- gives the character the effect belongs to health back, or whoever it names, once + for nothing, up to what an avatar
-- has at most. true if it was theirs to get: nothing brings back who's already down. whether one character may do
-- another that good is asked by whoever fires it
return ServerVFX.newEvent("Heal", isProperties, function(props: Properties, scope: ServerScope): boolean
	local character = props.Target or scope.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if
		not character
		or not humanoid
		or humanoid.Health <= 0
		or AttributeDefinition.get(character, AttributeDefinition.IsDead)
	then
		return false
	end
	-- a body nobody plays may have more than an avatar gets to: it's never left with less than it had
	local health = AttributeDefinition.get(character, AttributeDefinition.Health)
	AttributeDefinition.set(
		character,
		AttributeDefinition.Health,
		math.max(health, math.min(MAX_HEALTH, health + props.Amount))
	)
	return true
end)
