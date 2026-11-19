--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local FightingUtil = require("@game/ServerScriptService/Server/Util/Fighting")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type Fighting = CombatType.Fighting
-- Constants
-- what a loss of health comes to in the game, written down apart from its rule. a game that isn't listed keeps nobody
-- out of its menus, whatever they lost
local FIGHTING: Fighting? = GameDefinition.tune(nil :: Fighting?, {
	shl3 = {
		Duration = 15,
		MaxDuration = 30,
	},
})
-- on the clock of a server that's been up for a while
local START_TIME = 1000
-- Variables
-- References
-- Private Functions
local function newAvatar(): Model
	local avatar = Instance.new("Model")
	AttributeDefinition.setDefaults(avatar, "Character")
	return avatar
end

local function getFightingUntil(avatar: Model): number?
	return AttributeDefinition.get(avatar, AttributeDefinition.FightingUntil)
end

-- a game that keeps a fight out of its menus: each loss of health adds to the fight, up to as long as one gets
local function walkClock(fighting: Fighting)
	local duration, maxDuration = fighting.Duration, fighting.MaxDuration
	local avatar = newAvatar()
	assert(getFightingUntil(avatar) == nil, `a new avatar starts out in a fight`)
	assert(not CombatDefinition.getIfFighting(getFightingUntil(avatar), START_TIME), `a new avatar counts as fighting`)

	FightingUtil.hit(avatar, START_TIME)
	local fightingUntil = getFightingUntil(avatar)
	assert(fightingUntil == START_TIME + duration, `one hit is a fight until {fightingUntil}`)

	-- the second adds to what's left of the first, which comes to the most a fight lasts
	FightingUtil.hit(avatar, START_TIME + 1)
	fightingUntil = getFightingUntil(avatar)
	assert(fightingUntil == START_TIME + 2 * duration, `two hits are a fight until {fightingUntil}`)
	assert(2 * duration == maxDuration, `two hits don't fill a fight up, this spec is out of date`)

	-- nothing is added past that, the fight is as long as it gets from the last hit on
	FightingUtil.hit(avatar, START_TIME + 2)
	fightingUntil = getFightingUntil(avatar)
	assert(fightingUntil == START_TIME + 2 + maxDuration, `three hits are a fight until {fightingUntil}`)

	assert(CombatDefinition.getIfFighting(fightingUntil, START_TIME + 2), `a fight isn't on right after a hit`)
	assert(CombatDefinition.getIfFighting(fightingUntil, START_TIME + 1 + maxDuration), `a fight is over early`)
	assert(not CombatDefinition.getIfFighting(fightingUntil, START_TIME + 2 + maxDuration), `a fight outlasts itself`)

	-- a fight that's over leaves nothing for the next one to add to
	local laterTime = START_TIME + 10 * maxDuration
	FightingUtil.hit(avatar, laterTime)
	fightingUntil = getFightingUntil(avatar)
	assert(fightingUntil == laterTime + duration, `a hit after a fight is a fight until {fightingUntil}`)

	-- whoever goes down in it is out of it
	FightingUtil.clear(avatar)
	assert(getFightingUntil(avatar) == nil, `a death leaves the fight on`)
	assert(not CombatDefinition.getIfFighting(getFightingUntil(avatar), laterTime), `the dead count as fighting`)
end

-- a game that doesn't: nothing is ever written, + a time that's there anyway keeps nobody out of anything
local function walkNoClock()
	local avatar = newAvatar()
	for index = 0, 2 do
		FightingUtil.hit(avatar, START_TIME + index)
		assert(getFightingUntil(avatar) == nil, `a hit was written down in a game that keeps no fight`)
	end
	assert(CombatDefinition.getFightingUntil(nil, START_TIME) == nil, `the game has a time for a fight`)
	assert(CombatDefinition.getFightingUntil(START_TIME + 1, START_TIME) == nil, `the game adds to a fight`)
	assert(not CombatDefinition.getIfFighting(START_TIME + 1, START_TIME), `a fight is on in a game that keeps none`)
	FightingUtil.clear(avatar)
	assert(getFightingUntil(avatar) == nil, `a death wrote a fight down`)
end

-- the way into a menu is shut for as long as the fight is on, the way out of one never is
local function walkMenu(fighting: Fighting)
	local avatar = newAvatar()
	assert(FightingUtil.getMenuRefusal(avatar, true, START_TIME) == nil, `an avatar nobody hurt is kept out`)
	assert(FightingUtil.getMenuRefusal(nil, true, START_TIME) == nil, `a player without an avatar is kept out`)

	FightingUtil.hit(avatar, START_TIME)
	local fightingUntil = START_TIME + fighting.Duration
	local refusal = FightingUtil.getMenuRefusal(avatar, true, START_TIME + 1)
	assert(refusal ~= nil, `an avatar that was just hit is let into a menu`)
	assert(CombatType.MenuRefusal(refusal))
	assert(table.isfrozen(refusal), `the refusal isn't frozen`)
	assert(refusal.Type == "Fighting" and refusal.Until == fightingUntil, `the refusal names another fight`)
	assert(FightingUtil.getMenuRefusal(avatar, false, START_TIME + 1) == nil, `no way out of a menu in a fight`)

	-- every hit keeps it shut for longer
	FightingUtil.hit(avatar, START_TIME + 1)
	refusal = FightingUtil.getMenuRefusal(avatar, true, fightingUntil)
	assert(refusal ~= nil and refusal.Until > fightingUntil, `a second hit didn't keep the menu shut for longer`)

	-- it opens by itself once the fight ran out, + right away for whoever went down in it
	fightingUntil = refusal.Until
	assert(
		FightingUtil.getMenuRefusal(avatar, true, fightingUntil - 1) ~= nil,
		`the menu opens before the fight is over`
	)
	assert(FightingUtil.getMenuRefusal(avatar, true, fightingUntil) == nil, `the menu stays shut after the fight`)
	FightingUtil.hit(avatar, fightingUntil)
	assert(FightingUtil.getMenuRefusal(avatar, true, fightingUntil) ~= nil, `the next fight leaves the menu open`)
	FightingUtil.clear(avatar)
	assert(FightingUtil.getMenuRefusal(avatar, true, fightingUntil) == nil, `the dead are kept out of a menu`)
end

-- nobody is ever turned down in a game that keeps no fight, not for a time that got onto their avatar anyway
local function walkNoMenu()
	local avatar = newAvatar()
	FightingUtil.hit(avatar, START_TIME)
	AttributeDefinition.set(avatar, AttributeDefinition.FightingUntil, START_TIME + 60)
	for _, isInMenu in { true, false } do
		assert(
			FightingUtil.getMenuRefusal(avatar, isInMenu, START_TIME + 1) == nil,
			`somebody was turned down in a game that keeps no fight`
		)
	end
end
-- Class
return {
	-- the rule of the game says what's written down here
	Rule = SpecUtil.newScenario(function()
		assert(SpecUtil.getIfEqual(CombatDefinition.FIGHTING, FIGHTING), `the game times a fight another way`)
	end),

	-- one hit, two, three, a fight that ran out + one that ended in a death
	Clock = SpecUtil.newScenario(function()
		if FIGHTING then
			walkClock(FIGHTING)
		else
			walkNoClock()
		end
	end),

	Menu = SpecUtil.newScenario(function()
		if FIGHTING then
			walkMenu(FIGHTING)
		else
			walkNoMenu()
		end
	end),
}
