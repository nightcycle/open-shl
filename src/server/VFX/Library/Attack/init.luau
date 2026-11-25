--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local CoverUtil = require("@game/ServerScriptService/Server/Util/Cover")
local Damage = require("@game/ServerScriptService/Server/VFX/Library/Damage")
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
local Shove = require("@game/ServerScriptService/Server/VFX/Library/Shove")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerScope = VFXType.ServerScope
export type Properties = {
	Target: Model,
	Amount: number,
	Origin: Vector3?, -- where what hit them left from: a cover between there + them takes it
	IsStill: boolean?, -- it doesn't send them off
}
-- Constants
local isProperties = Type.strictInterface({
	Target = Type.instanceIsA("Model"),
	Amount = Type.numberMin(0),
	Origin = Type.optional(Type.Vector3),
	IsStill = Type.optional(Type.boolean),
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
	-- what somebody carries between the two takes it, whatever the client that claims the hit made of its way there
	local origin = props.Origin
	if origin and CoverUtil.getIfBetween(origin, target, character) then
		return false
	end
	local isLanded = scope.fire(Damage, {
		Target = target,
		Amount = amount,
	})
	-- the hit that took the last of somebody's health is the only one that can say so: a body that's down takes no
	-- other. it's said where downing somebody is worth something to whoever did, for whoever pays to read once
	local player = scope.Player
	if
		isLanded
		and player
		and CombatDefinition.BOUNTY
		and AttributeDefinition.get(target, AttributeDefinition.IsDead)
	then
		AttributeDefinition.set(target, AttributeDefinition.DownedBy, player.UserId)
	end
	-- only a hit that got through sends them off: whatever keeps the health of somebody keeps them where they are
	local knockback = CombatDefinition.KNOCKBACK
	if isLanded and knockback and character and not props.IsStill then
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
