--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local FightingUtil = require("@game/ServerScriptService/Server/Util/Fighting")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local PlayerModeUtil = require("@game/ServerScriptService/Server/Util/PlayerMode")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
type TestMap = SimpleTest.TestMap
-- Constants
-- on the clock of a server that's been up for a while
local START_TIME = 1000
-- Variables
-- References
-- Private Functions
-- an avatar nobody plays: a body with the attributes every avatar comes in with
local function newAvatar(isPeaceful: boolean): Model
	local avatar = Instance.new("Model")
	local humanoid = Instance.new("Humanoid")
	humanoid.Health = humanoid.MaxHealth
	humanoid.Parent = avatar
	AttributeDefinition.setDefaults(avatar, "Character")
	PlayerModeUtil.apply(avatar, isPeaceful)
	return avatar
end

local function getHumanoid(avatar: Model): Humanoid
	local humanoid = avatar:FindFirstChildWhichIsA("Humanoid")
	assert(humanoid, `the avatar has no humanoid`)
	return humanoid
end

local function getIfPeaceful(avatar: Model): boolean?
	return AttributeDefinition.get(avatar, AttributeDefinition.IsPeaceful)
end

local function getIfDown(avatar: Model): boolean
	return AttributeDefinition.get(avatar, AttributeDefinition.IsDead)
		and AttributeDefinition.get(avatar, AttributeDefinition.Health) == 0
		and getHumanoid(avatar).Health == 0
end

local function getIfUntouched(avatar: Model): boolean
	return not AttributeDefinition.get(avatar, AttributeDefinition.IsDead)
		and AttributeDefinition.get(avatar, AttributeDefinition.Health) == AttributeDefinition.Health.Default
		and getHumanoid(avatar).Health > 0
end
-- Class
local Tests: TestMap = {
	-- a hit only lands from one who fights onto one who fights
	Rule = SpecUtil.newScenario(function()
		assert(CombatDefinition.IS_OPTIONAL, `the rule of the game has nobody sit a fight out`)
		assert(ModeDefinition.getIfPVPEnabled(), `the place has nobody fight, the pick of a player decides nothing`)
		local fighter, other = newAvatar(false), newAvatar(false)
		local sitter, otherSitter = newAvatar(true), newAvatar(true)
		assert(getIfPeaceful(fighter) == false and getIfPeaceful(sitter) == true, `an avatar didn't take its pick`)
		assert(CombatDefinition.getIfHostile(fighter, other), `two who fight can't hurt each other`)
		assert(CombatDefinition.getDamage(fighter, other, 20) == 20, `a hit between two who fight comes to another one`)
		assert(not CombatDefinition.getIfHostile(fighter, sitter), `one who sat fights out is hurt`)
		assert(not CombatDefinition.getIfHostile(sitter, fighter), `one who sat fights out hurts somebody`)
		assert(not CombatDefinition.getIfHostile(sitter, otherSitter), `two who sat fights out hurt each other`)
		assert(CombatDefinition.getDamage(sitter, fighter, 20) == nil, `a hit of one who sat fights out lands`)
		-- an avatar that says nothing (one that isn't a player's) fights
		local dummy = Instance.new("Model")
		assert(CombatDefinition.getIfHostile(fighter, dummy), `an avatar that says nothing can't be hurt`)
	end),

	-- an avatar that came in behind a menu + wasn't let out of it takes a new pick as it stands
	Held = SpecUtil.newScenario(function()
		local avatar = newAvatar(false)
		PlayerModeUtil.change(avatar, true, true)
		assert(getIfPeaceful(avatar) == true, `a held avatar didn't take the pick`)
		assert(getIfUntouched(avatar), `a held avatar paid for the pick`)
		PlayerModeUtil.change(avatar, true, false)
		assert(getIfPeaceful(avatar) == false, `a held avatar didn't take the pick back`)
		assert(getIfUntouched(avatar), `a held avatar paid for the pick`)
	end),

	-- one that's been in the world goes down for it, whatever it had left + whatever kept it from harm. the body that
	-- goes down is still what it was: the one that comes back is the first to play by the pick
	World = SpecUtil.newScenario(function()
		for _, isPeaceful in { true, false } do
			local avatar = newAvatar(not isPeaceful)
			local forceField = Instance.new("ForceField")
			forceField.Parent = avatar
			AttributeDefinition.set(avatar, AttributeDefinition.IsInvulnerable, true)
			FightingUtil.hit(avatar, START_TIME)
			PlayerModeUtil.change(avatar, false, isPeaceful)
			assert(getIfDown(avatar), `an avatar changed sides + is still up`)
			assert(getIfPeaceful(avatar) == not isPeaceful, `the body that went down changed sides`)
			assert(
				AttributeDefinition.get(avatar, AttributeDefinition.FightingUntil) == nil,
				`a death for the pick leaves a fight on`
			)
		end
	end),

	-- there's nothing to take down twice, + nothing at all where no avatar is out
	Gone = SpecUtil.newScenario(function()
		local avatar = newAvatar(false)
		PlayerModeUtil.change(avatar, false, true)
		assert(getIfDown(avatar), `the avatar is still up`)
		PlayerModeUtil.change(avatar, false, false)
		assert(getIfDown(avatar) and getIfPeaceful(avatar) == false, `the dead changed sides`)
		PlayerModeUtil.change(nil, false, true)
		PlayerModeUtil.change(nil, true, true)
		-- a body without a humanoid isn't an avatar anybody could take down
		local husk = Instance.new("Model")
		PlayerModeUtil.change(husk, false, true)
		assert(not AttributeDefinition.get(husk, AttributeDefinition.IsDead), `a husk was taken down`)
	end),
}

-- only a game where who fights is each player's own pick has anything to hold this to
return if GameDefinition.FEATURES.PlayerMode then Tests else {} :: TestMap
