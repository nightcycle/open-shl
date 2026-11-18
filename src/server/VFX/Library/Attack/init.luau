--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local Damage = require("@game/ServerScriptService/Server/VFX/Library/Damage")
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
local Shove = require("@game/ServerScriptService/Server/VFX/Library/Shove")
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
-- a character hurting another one, as far as the mode + the rules of the game let them. true if it landed
return ServerVFX.newEvent("Attack", isProperties, function(props: Properties, scope: ServerScope): boolean
	local character = scope.Character
	local target = props.Target
	local amount = CombatDefinition.getDamage(character, target, props.Amount)
	if not amount then
		return false
	end
	local isLanded = scope.fire(Damage, {
		Target = target,
		Amount = amount,
	})
	-- only a hit that got through sends them off: whatever keeps the health of somebody keeps them where they are
	local knockback = CombatDefinition.KNOCKBACK
	if isLanded and knockback and character then
		local velocity = CombatDefinition.getKnockback(character:GetPivot().Position, target:GetPivot().Position)
		if velocity then
			scope.fire(Shove, {
				Target = target,
				Velocity = velocity,
				Duration = knockback.Duration,
				MaxForce = knockback.MaxForce,
				Power = knockback.Power,
			})
		end
	end
	return isLanded
end)
