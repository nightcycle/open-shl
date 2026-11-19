--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local FightingUtil = require("@game/ServerScriptService/Server/Util/Fighting")
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
-- takes health off a character, whoever asks + whatever the rules of the mode. true if it landed, which it never
-- does on one that's invulnerable
return ServerVFX.newEvent("Damage", isProperties, function(props: Properties): boolean
	local target = props.Target
	local humanoid = target:FindFirstChildWhichIsA("Humanoid")
	if not humanoid or humanoid.Health <= 0 or AttributeDefinition.get(target, AttributeDefinition.IsDead) then
		return false
	end
	if AttributeDefinition.get(target, AttributeDefinition.IsInvulnerable) then
		return false
	end
	local priorHealth = AttributeDefinition.get(target, AttributeDefinition.Health)
	local health = math.max(0, priorHealth - props.Amount)
	AttributeDefinition.set(target, AttributeDefinition.Health, health)
	if health <= 0 then
		AttributeDefinition.set(target, AttributeDefinition.IsDead, true)
		FightingUtil.clear(target)
		humanoid.Health = 0
	elseif health < priorHealth and CombatDefinition.FIGHTING then
		-- whatever takes health off a character comes through here, so this is where a game that keeps a fight out
		-- of its menus counts one from
		FightingUtil.hit(target, CombatDefinition.getTime())
	end
	return true
end)
