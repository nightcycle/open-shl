--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
-- Types
export type Properties = {
	Target: Model,
	Amount: number,
}
-- Constants
local isProperties = Type.strictInterface({
	Target = Type.instanceIsA("Model"),
	Amount = Type.numberMin(0),
})
-- Variables
-- References
-- Private Functions
-- Class
-- takes health off a character, whoever asks + whatever the rules of the mode. true if it landed
return ServerVFX.newEvent("Damage", isProperties, function(props: Properties): boolean
	local target = props.Target
	local humanoid = target:FindFirstChildWhichIsA("Humanoid")
	if not humanoid or humanoid.Health <= 0 or AttributeDefinition.get(target, AttributeDefinition.IsDead) then
		return false
	end
	local health = math.max(0, AttributeDefinition.get(target, AttributeDefinition.Health) - props.Amount)
	AttributeDefinition.set(target, AttributeDefinition.Health, health)
	if health <= 0 then
		AttributeDefinition.set(target, AttributeDefinition.IsDead, true)
		humanoid.Health = 0
	end
	return true
end)
