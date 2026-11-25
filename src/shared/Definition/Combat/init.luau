--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
export type Fighting = CombatType.Fighting
export type Knockback = CombatType.Knockback
export type Regeneration = CombatType.Regeneration
export type Bounty = CombatType.Bounty
export type CombatRule = CombatType.CombatRule
-- Constants
-- what a hit comes to is the game's own, the rule of another game is never required
local RULE: CombatRule = GameDefinition.pick({
	shl1 = function(): CombatRule
		return require("@self/SHL1")
	end,
	shl2 = function(): CombatRule
		return require("@self/SHL2")
	end,
	shl3 = function(): CombatRule
		return require("@self/SHL3")
	end,
})
assert(CombatType.CombatRule(RULE))
TableUtil.deepFreeze(RULE)
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- how somebody who's hit is kept on their way, nil in a game that doesn't send them off
Module.KNOCKBACK = RULE.Knockback

-- what everybody gets back by themselves, nil in a game where health only comes back by a power
Module.REGENERATION = RULE.Regeneration

-- if nobody is hurt while they sit in a menu, + nobody hurts anybody from one
Module.IS_MENU_SAFE = RULE.IsMenuSafe

-- if who fights is each player's own pick: whoever sat fights out hurts nobody + nobody hurts them
Module.IS_OPTIONAL = RULE.IsOptional == true

-- if nobody is hurt by their own side. nil in a game whose players take none
Module.IS_TEAM_SAFE = RULE.IsTeamSafe

-- if whoever is held in jail is left alone until they make trouble. nil in a game that holds nobody
Module.IS_JAIL_SAFE = RULE.IsJailSafe

-- what downing somebody is worth + on which side, nil in a game where nobody is paid for it
Module.BOUNTY = RULE.Bounty

-- how long a loss of health keeps the two of it out of the menus, who lost it + who took it off them. nil in a game
-- where they get into one whenever
Module.FIGHTING = RULE.Fighting

-- the clock a fight is timed on: the server's, every client keeps up with it by itself
Module.getTime = function(): number
	return Workspace:GetServerTimeNow()
end

-- when the fight of somebody who loses health right now is over, + of whoever takes it off them: a loss adds to
-- what's left of the one before, as far off as the game lets a fight get. nil in a game that keeps no such time
Module.getFightingUntil = function(fightingUntil: number?, now: number): number?
	local fighting = RULE.Fighting
	if not fighting then
		return nil
	end
	local startTime = math.max(fightingUntil or now, now)
	return math.min(startTime + fighting.Duration, now + fighting.MaxDuration)
end

-- if the fight that's over at that time is still on. both sides can ask, only what the server makes of it counts
Module.getIfFighting = function(fightingUntil: number?, now: number): boolean
	return RULE.Fighting ~= nil and fightingUntil ~= nil and now < fightingUntil
end

-- whether one character may do anything unkind to another: hurt it, hold it, drag it. both sides can ask, only what
-- the server makes of it counts
Module.getIfHostile = function(attacker: Model?, victim: Model): boolean
	-- a place without pvp has nobody hurt anybody, nobody hurts themselves anywhere
	if not ModeDefinition.getIfPVPEnabled() or victim == attacker then
		return false
	end
	-- a menu shelters whoever sits in it, so whoever sits in one hurts nobody either: what they sent off before they
	-- went in is asked about as it lands
	if RULE.IsMenuSafe then
		local isInMenu = AttributeDefinition.get(victim, AttributeDefinition.IsInMenu)
			or (attacker ~= nil and AttributeDefinition.get(attacker, AttributeDefinition.IsInMenu))
		if isInMenu then
			return false
		end
	end
	-- somebody of a side leaves their own alone. a body that's on none is on nobody's
	if RULE.IsTeamSafe and attacker ~= nil then
		local teamId = AttributeDefinition.get(victim, AttributeDefinition.TeamId)
		if teamId ~= nil and teamId == AttributeDefinition.get(attacker, AttributeDefinition.TeamId) then
			return false
		end
	end
	-- whoever sits in jail is left alone until they make trouble
	if
		RULE.IsJailSafe
		and AttributeDefinition.get(victim, AttributeDefinition.IsJailed) == true
		and AttributeDefinition.get(victim, AttributeDefinition.IsTroublesome) ~= true
	then
		return false
	end
	-- one who sat fights out is left alone + leaves everybody alone
	if RULE.IsOptional then
		local isPeaceful = AttributeDefinition.get(victim, AttributeDefinition.IsPeaceful) == true
			or (attacker ~= nil and AttributeDefinition.get(attacker, AttributeDefinition.IsPeaceful) == true)
		if isPeaceful then
			return false
		end
	end
	-- the force field a spot hands whoever comes in on it, for as long as the engine leaves it up
	if RULE.IsShieldSafe and victim:FindFirstChildWhichIsA("ForceField") ~= nil then
		return false
	end
	return true
end

-- what a hit of that much takes off the character it's meant for, nil if the rules don't let it land. both sides
-- can ask, only what the server makes of it counts
Module.getDamage = function(attacker: Model?, victim: Model, amount: number): number?
	if not Module.getIfHostile(attacker, victim) then
		return nil
	end
	-- what a game adds to a hit it adds on an avatar, a body nobody plays takes what the power says
	local isNonPlayer = AttributeDefinition.get(victim, AttributeDefinition.IsNonPlayer) == true
	return amount * (if isNonPlayer then 1 else RULE.PlayerScale)
end

-- what whoever downs that character is paid: the price on the head of its side, + as much again for everybody it
-- downed since it came in. nil for one nobody is paid for. both sides can ask, only the server pays
Module.getBounty = function(victim: Model): number?
	local bounty = RULE.Bounty
	if not bounty or AttributeDefinition.get(victim, AttributeDefinition.TeamId) ~= bounty.TeamId then
		return nil
	end
	local killStreak = AttributeDefinition.get(victim, AttributeDefinition.KillStreak) or 0
	return (killStreak + 1) * bounty.Amount
end

-- the pace somebody who's hit is sent off at, away from whoever hit them. nil in a game that doesn't send them off +
-- for one who's right above or below: there's no way that's away
Module.getKnockback = function(attackerPosition: Vector3, victimPosition: Vector3): Vector3?
	local knockback = RULE.Knockback
	if not knockback then
		return nil
	end
	local offset = (victimPosition - attackerPosition) * Vector3.new(1, 0, 1)
	-- the further of the two flat axes is the one that's at the full pace, so it's quicker on a diagonal
	local length = math.max(math.abs(offset.X), math.abs(offset.Z))
	if length <= 0 then
		return nil
	end
	return offset * knockback.Speed / length
end

return Module
