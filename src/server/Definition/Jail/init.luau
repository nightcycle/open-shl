--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PropDefinition = require("@game/ReplicatedStorage/Shared/Definition/Prop")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type IdentityKey = CharacterType.IdentityKey
type TeamId = CombatType.TeamId
-- how a pane that keeps the held in lets somebody through: it fades, is out of the way for a while + fades back in
export type Gate = {
	OpenDuration: number, -- seconds it's out of the way for, whoever walks up meanwhile
	FadeDuration: number, -- seconds either fade takes
	FadeTransparency: number, -- what it's at through a fade
	OpenTransparency: number, -- + while it's out of the way
}
-- the jail of a game: nobody is put in it by anybody, it's where the avatars of one side come in. being let out is
-- getting away from it
export type Rule = {
	-- the side whose avatars come in held
	TeamId: TeamId,
	-- who somebody is for as long as they're held, whoever they came as
	IdentityKey: IdentityKey,
	-- what they're put in over what that identity wears, every piece in the one color
	ItemIds: { string },
	Color: Color3,
	-- seconds between two looks at where the held are
	CheckInterval: number,
	-- studs under the root of somebody a road counts as stood on
	RoadReach: number,
	-- seconds from being let go to having the powers back
	ReleaseDelay: number,
	Gate: Gate,
	-- the prop that opens a gate for whoever has it in their hand
	KeyPropId: string,
}
-- Constants
local isRule = Type.strictInterface({
	TeamId = CombatType.TeamId,
	IdentityKey = CharacterType.IdentityKey,
	ItemIds = Type.array(Type.string),
	Color = Type.Color3,
	CheckInterval = Type.numberPositive,
	RoadReach = Type.numberPositive,
	ReleaseDelay = Type.numberMin(0),
	Gate = Type.strictInterface({
		OpenDuration = Type.numberPositive,
		FadeDuration = Type.numberMin(0),
		FadeTransparency = Type.numberConstrained(0, 1),
		OpenTransparency = Type.numberConstrained(0, 1),
	}),
	KeyPropId = Type.string,
})
-- the jail of a game is its own, the rule of another game is never required
local RULE: Rule = GameDefinition.pick({
	shl1 = function(): Rule
		error(`shl1 has no jail`)
	end,
	shl2 = function(): Rule
		error(`shl2 has no jail`)
	end,
	shl3 = function(): Rule
		return require("@self/SHL3")
	end,
})
assert(isRule(RULE))
TableUtil.deepFreeze(RULE)
-- what the held wear + what lets them out are rows of the game, one that's spelt wrong would only show on the first
-- of them
for _, id in RULE.ItemIds do
	local definitionRes = ItemAppearanceDefinition.get(id)
	assert(definitionRes.IsOk, `the jail: {definitionRes.Value}`)
end
do
	local definitionRes = PropDefinition.get(RULE.KeyPropId)
	assert(definitionRes.IsOk, `the jail: {definitionRes.Value}`)
end
-- Variables
-- References
-- Private Functions
-- Class
-- every field is in from the start, one that's assigned afterwards the checker only knows for the widest type it has
local Module = {
	TEAM_ID = RULE.TeamId,
	IDENTITY_KEY = RULE.IdentityKey,
	ITEM_IDS = RULE.ItemIds,
	COLOR = RULE.Color,
	CHECK_INTERVAL = RULE.CheckInterval,
	ROAD_REACH = RULE.RoadReach,
	RELEASE_DELAY = RULE.ReleaseDelay,
	GATE = RULE.Gate,
	KEY_PROP_ID = RULE.KeyPropId,
}

return Module
