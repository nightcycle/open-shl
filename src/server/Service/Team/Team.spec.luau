--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BalanceUtil = require("@game/ServerScriptService/Server/Service/Team/Balance")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type TestMap = SimpleTest.TestMap
type TeamId = CombatType.TeamId
-- Constants
-- Variables
-- References
-- Private Functions
-- an avatar nobody plays: a body with the attributes every avatar comes in with, on a side or on none
local function newAvatar(teamId: TeamId?): Model
	local avatar = Instance.new("Model")
	local humanoid = Instance.new("Humanoid")
	humanoid.Health = humanoid.MaxHealth
	humanoid.Parent = avatar
	AttributeDefinition.setDefaults(avatar, "Character")
	AttributeDefinition.set(avatar, AttributeDefinition.TeamId, teamId)
	AttributeDefinition.set(avatar, AttributeDefinition.KillStreak, if teamId then 0 else nil)
	return avatar
end
-- Class
local Tests: TestMap = {
	-- whoever comes in goes where there are fewer, to the side the game says while neither is ahead
	Join = SpecUtil.newScenario(function()
		assert(BalanceUtil.getOther("Heroes") == "Villains", `the other side of the heroes is their own`)
		assert(BalanceUtil.getOther("Villains") == "Heroes", `the other side of the villains is their own`)
		assert(BalanceUtil.getJoinTeamId({}, "Heroes") == "Heroes", `the first in isn't put where a tie goes`)
		assert(BalanceUtil.getJoinTeamId({ Heroes = 1, Villains = 1 }, "Heroes") == "Heroes", `a tie`)
		assert(BalanceUtil.getJoinTeamId({ Heroes = 1, Villains = 1 }, "Villains") == "Villains", `a tie the other way`)
		assert(BalanceUtil.getJoinTeamId({ Heroes = 1, Villains = 0 }, "Heroes") == "Villains", `the side with fewer`)
		assert(BalanceUtil.getJoinTeamId({ Heroes = 2, Villains = 5 }, "Villains") == "Heroes", `the side with fewer`)
	end),

	-- nobody leaves for a side that's ahead of theirs by more than the lead, themselves counted with their own
	Switch = SpecUtil.newScenario(function()
		assert(BalanceUtil.getIfSwitchAllowed({ Heroes = 3, Villains = 5 }, "Heroes", 2), `3 against 5 keeps a hero`)
		assert(not BalanceUtil.getIfSwitchAllowed({ Heroes = 2, Villains = 6 }, "Heroes", 2), `2 against 6 lets one go`)
		assert(
			BalanceUtil.getIfSwitchAllowed({ Heroes = 2, Villains = 6 }, "Villains", 2),
			`the side ahead keeps its own`
		)
		-- the old place let its last hero go at one against three
		assert(BalanceUtil.getIfSwitchAllowed({ Heroes = 1, Villains = 3 }, "Heroes", 2), `1 against 3 keeps a hero`)
		assert(not BalanceUtil.getIfSwitchAllowed({ Heroes = 1, Villains = 4 }, "Heroes", 2), `1 against 4 lets one go`)
		assert(BalanceUtil.getIfSwitchAllowed({ Heroes = 1, Villains = 1 }, "Heroes", 0), `even sides keep somebody`)
		assert(not BalanceUtil.getIfSwitchAllowed({ Heroes = 1, Villains = 2 }, "Heroes", 0), `no lead is no lead`)
	end),

	-- who the rule of the game has hurt whom once there are sides, + what downing somebody pays
	Sides = SpecUtil.newScenario(function()
		assert(CombatDefinition.IS_TEAM_SAFE, `the rule of the game has no sides`)
		assert(ModeDefinition.getIfPVPEnabled(), `the place has nobody fight, a side decides nothing`)
		local hero, otherHero = newAvatar("Heroes"), newAvatar("Heroes")
		local villain, otherVillain = newAvatar("Villains"), newAvatar("Villains")
		local stranger = newAvatar(nil)
		assert(CombatDefinition.getIfHostile(hero, villain), `a hero doesn't get to a villain`)
		assert(CombatDefinition.getIfHostile(villain, hero), `a villain doesn't get to a hero`)
		assert(not CombatDefinition.getIfHostile(hero, otherHero), `a hero gets to a hero`)
		assert(not CombatDefinition.getIfHostile(villain, otherVillain), `a villain gets to a villain`)
		-- a body that's on no side is on nobody's
		assert(CombatDefinition.getIfHostile(stranger, hero), `a body on no side doesn't get to a hero`)
		assert(CombatDefinition.getIfHostile(hero, stranger), `a hero doesn't get to a body on no side`)
		assert(CombatDefinition.getIfHostile(nil, hero), `a loss nobody is behind doesn't land`)

		if CombatDefinition.IS_JAIL_SAFE then
			AttributeDefinition.set(villain, AttributeDefinition.IsJailed, true)
			AttributeDefinition.set(villain, AttributeDefinition.IsTroublesome, false)
			assert(not CombatDefinition.getIfHostile(hero, villain), `a hero gets to a villain that's held`)
			assert(not CombatDefinition.getIfHostile(stranger, villain), `a body on no side gets to one`)
			assert(not CombatDefinition.getIfHostile(nil, villain), `a loss nobody is behind lands on one`)
			assert(CombatDefinition.getDamage(hero, villain, 10) == nil, `a hit on one comes to something`)
			AttributeDefinition.set(villain, AttributeDefinition.IsTroublesome, true)
			assert(CombatDefinition.getIfHostile(hero, villain), `trouble doesn't end being left alone`)
			assert(not CombatDefinition.getIfHostile(otherVillain, villain), `trouble sets a side on its own`)
			AttributeDefinition.set(villain, AttributeDefinition.IsTroublesome, false)
			AttributeDefinition.set(villain, AttributeDefinition.IsJailed, false)
			assert(CombatDefinition.getIfHostile(hero, villain), `a villain that got away is still left alone`)
		end

		local bounty = CombatDefinition.BOUNTY
		if bounty then
			local wanted = if bounty.TeamId == "Villains" then otherVillain else otherHero
			local unwanted = if bounty.TeamId == "Villains" then otherHero else otherVillain
			assert(CombatDefinition.getBounty(wanted) == bounty.Amount, `nobody downed isn't the price by itself`)
			AttributeDefinition.set(wanted, AttributeDefinition.KillStreak, 9)
			assert(CombatDefinition.getBounty(wanted) == 10 * bounty.Amount, `nine downed isn't ten times the price`)
			AttributeDefinition.set(unwanted, AttributeDefinition.KillStreak, 9)
			assert(CombatDefinition.getBounty(unwanted) == nil, `the other side has a price on its head`)
			assert(CombatDefinition.getBounty(stranger) == nil, `a body on no side has a price on its head`)
		end
	end),
}

-- only a game whose players take a side has anything to hold this to
return if GameDefinition.FEATURES.Teams then Tests else {} :: TestMap
