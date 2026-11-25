--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local FightingUtil = require("@game/ServerScriptService/Server/Util/Fighting")
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
local TallyUtil = require("@game/ServerScriptService/Server/Util/Tally")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerScope = VFXType.ServerScope
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
return ServerVFX.newEvent("Damage", isProperties, function(props: Properties, scope: ServerScope): boolean
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
	-- what a player took off a body somebody keeps count on, which is never more than it had left
	local taken = priorHealth - health
	if taken > 0 and scope.Player then
		TallyUtil.add(target, scope.Player, taken)
	end
	local isDown = health <= 0
	if isDown then
		AttributeDefinition.set(target, AttributeDefinition.IsDead, true)
		FightingUtil.clear(target)
		humanoid.Health = 0
	end
	if health < priorHealth and CombatDefinition.FIGHTING then
		-- whatever takes health off a character comes through here, so this is where a game that keeps a fight out
		-- of its menus counts one from: for whoever lost it + is still up, + for the character the effect belongs
		-- to, who took it off them
		local now = CombatDefinition.getTime()
		if not isDown then
			FightingUtil.hit(target, now)
		end
		FightingUtil.land(scope.Character, target, now)
	end
	return true
end)
