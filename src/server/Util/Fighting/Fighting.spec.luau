--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local FightingUtil = require("@game/ServerScriptService/Server/Util/Fighting")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type Fighting = CombatType.Fighting
-- Constants
-- what a loss of health comes to in the game, written down apart from its rule. a game that isn't listed keeps nobody
-- out of its menus, whatever they lost
local FIGHTING: Fighting? = GameDefinition.tune(nil :: Fighting?, {
	shl1 = {
		Duration = 15,
		MaxDuration = 30,
	},
	shl3 = {
		Duration = 15,
		MaxDuration = 30,
	},
})
-- if a menu of the game shelters whoever sits in it, written down apart from its rule as well. in a game that isn't
-- listed everybody hits + is hit wherever they sit
local IS_MENU_SAFE = GameDefinition.tune(false, { shl1 = true, shl3 = true })
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

-- whoever lands a hit is in the fight they started: for as long as whoever they hit, + no longer than a fight gets
local function walkAttacker(fighting: Fighting)
	local duration, maxDuration = fighting.Duration, fighting.MaxDuration
	local attacker, victim = newAvatar(), newAvatar()
	FightingUtil.land(attacker, victim, START_TIME)
	assert(getFightingUntil(attacker) == START_TIME + duration, `one hit landed is no fight of {duration} seconds`)
	-- what the victim lost is counted where they lost it, not here
	assert(getFightingUntil(victim) == nil, `a hit that landed was counted for who it landed on`)
	assert(
		FightingUtil.getMenuRefusal(attacker, true, START_TIME + 1) ~= nil,
		`whoever just landed a hit gets into a menu`
	)

	FightingUtil.hit(victim, START_TIME)
	for index = 1, 2 do
		FightingUtil.land(attacker, victim, START_TIME + index)
		FightingUtil.hit(victim, START_TIME + index)
	end
	local fightingUntil = getFightingUntil(attacker)
	assert(fightingUntil == START_TIME + 2 + maxDuration, `three hits landed are a fight until {fightingUntil}`)
	assert(fightingUntil == getFightingUntil(victim), `the two of a fight aren't in it for as long`)

	-- a loss nobody is behind, one somebody brought on themselves + one that lands after whoever sent it went down
	local bystander = newAvatar()
	FightingUtil.land(nil, bystander, START_TIME)
	assert(getFightingUntil(bystander) == nil, `a loss without an attacker was counted as a hit landed`)
	FightingUtil.land(bystander, bystander, START_TIME)
	assert(getFightingUntil(bystander) == nil, `somebody landed a hit on themselves`)
	AttributeDefinition.set(bystander, AttributeDefinition.IsDead, true)
	FightingUtil.land(bystander, victim, START_TIME)
	assert(getFightingUntil(bystander) == nil, `the dead are in a fight for a hit that landed late`)
end

-- a game that keeps no fight has nobody in one for a hit they landed either
local function walkNoAttacker()
	local attacker, victim = newAvatar(), newAvatar()
	for index = 0, 2 do
		FightingUtil.land(attacker, victim, START_TIME + index)
		assert(getFightingUntil(attacker) == nil, `a hit landed was written down in a game that keeps no fight`)
		assert(getFightingUntil(victim) == nil, `a hit landed was counted for who it landed on`)
	end
end

-- a hit is asked about as it lands: whoever sits in a menu by then hurts nobody, wherever they stood as they sent it
-- off. a hit that's turned down takes no health, which is all a fight is ever counted from. a game whose menus
-- shelter nobody has it land from inside one + on whoever sits in one
local function walkSender()
	-- a place where nobody fights has nobody hurt anybody, in a menu or out of one
	local isLanding = ModeDefinition.getIfPVPEnabled()
	local isLandingInMenu = isLanding and not IS_MENU_SAFE
	local sender, target = newAvatar(), newAvatar()
	local function getIfLanding(attacker: Model?, victim: Model): boolean
		local isHostile = CombatDefinition.getIfHostile(attacker, victim)
		assert((CombatDefinition.getDamage(attacker, victim, 20) ~= nil) == isHostile, `a hit takes what it may not`)
		return isHostile
	end
	assert(getIfLanding(sender, target) == isLanding, `a hit between two who are out of a menu comes to another one`)

	-- out, a shot sent off, in before it lands
	AttributeDefinition.set(sender, AttributeDefinition.IsInMenu, true)
	assert(getIfLanding(sender, target) == isLandingInMenu, `a hit from inside a menu comes to another one`)
	assert(getIfLanding(target, sender) == isLandingInMenu, `a hit on somebody in a menu comes to another one`)
	-- what nobody is behind lands the way it did, on whoever is out
	assert(getIfLanding(nil, target) == isLanding, `a loss nobody is behind is kept off somebody who's out`)
	assert(getIfLanding(nil, sender) == isLandingInMenu, `a loss nobody is behind comes to another one in a menu`)
	assert(getFightingUntil(sender) == nil and getFightingUntil(target) == nil, `asking the rule started a fight`)

	-- back out their hits land again
	AttributeDefinition.set(sender, AttributeDefinition.IsInMenu, false)
	assert(getIfLanding(sender, target) == isLanding, `whoever left a menu hits another way than before it`)
	assert(getIfLanding(target, sender) == isLanding, `whoever left a menu is hit another way than before it`)
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

-- nobody becomes another character in a fight, but for whoever the server counts as in a menu: they were let in
local function walkCharacter(fighting: Fighting)
	local avatar = newAvatar()
	assert(FightingUtil.getCharacterRefusal(avatar, false, START_TIME) == nil, `an avatar nobody hurt stays who it is`)
	assert(FightingUtil.getCharacterRefusal(nil, false, START_TIME) == nil, `a player without an avatar is turned down`)

	FightingUtil.hit(avatar, START_TIME)
	local fightingUntil = START_TIME + fighting.Duration
	local refusal = FightingUtil.getCharacterRefusal(avatar, false, START_TIME + 1)
	assert(refusal ~= nil, `an avatar that was just hit becomes another character`)
	assert(CombatType.MenuRefusal(refusal))
	assert(table.isfrozen(refusal), `the refusal isn't frozen`)
	assert(refusal.Type == "Fighting" and refusal.Until == fightingUntil, `the refusal names another fight`)
	assert(
		SpecUtil.getIfEqual(refusal, FightingUtil.getMenuRefusal(avatar, true, START_TIME + 1)),
		`it isn't what a menu turns them down with`
	)
	-- whoever the server counts as in a menu was let into it: the menu they sit in is theirs to use
	assert(FightingUtil.getCharacterRefusal(avatar, true, START_TIME + 1) == nil, `a menu is shut to who sits in it`)

	-- whoever landed the hit is turned down the same
	local attacker = newAvatar()
	FightingUtil.land(attacker, avatar, START_TIME)
	assert(FightingUtil.getCharacterRefusal(attacker, false, START_TIME + 1) ~= nil, `whoever landed a hit is let go`)

	assert(
		FightingUtil.getCharacterRefusal(avatar, false, fightingUntil - 1) ~= nil,
		`they become another character before the fight is over`
	)
	assert(FightingUtil.getCharacterRefusal(avatar, false, fightingUntil) == nil, `they're kept as they are after it`)
	FightingUtil.hit(avatar, fightingUntil)
	FightingUtil.clear(avatar)
	assert(FightingUtil.getCharacterRefusal(avatar, false, fightingUntil) == nil, `the dead are kept as they were`)
end

-- everybody is whoever they ask to be in a game that keeps no fight
local function walkNoCharacter()
	local avatar = newAvatar()
	FightingUtil.hit(avatar, START_TIME)
	AttributeDefinition.set(avatar, AttributeDefinition.FightingUntil, START_TIME + 60)
	for _, isInMenu in { true, false } do
		assert(
			FightingUtil.getCharacterRefusal(avatar, isInMenu, START_TIME + 1) == nil,
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

	-- the one who lands a hit is in the fight as well
	Attacker = SpecUtil.newScenario(function()
		if FIGHTING then
			walkAttacker(FIGHTING)
		else
			walkNoAttacker()
		end
	end),

	-- fire, then hide: the shot of whoever sits in a menu lands on nobody
	Sender = SpecUtil.newScenario(function()
		assert(CombatDefinition.IS_MENU_SAFE == IS_MENU_SAFE, `the menus of the game shelter another way`)
		walkSender()
	end),

	Menu = SpecUtil.newScenario(function()
		if FIGHTING then
			walkMenu(FIGHTING)
		else
			walkNoMenu()
		end
	end),

	Character = SpecUtil.newScenario(function()
		if FIGHTING then
			walkCharacter(FIGHTING)
		else
			walkNoCharacter()
		end
	end),
}
