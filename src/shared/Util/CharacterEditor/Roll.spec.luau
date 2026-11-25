--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local CharacterConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local RollUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/Roll")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Character = CharacterType.Character
type Item = AppearanceType.Item
type TestMap = SimpleTest.TestMap
type TextureGroupKey = AppearanceType.TextureGroupKey
-- Constants
local TORSO_ID = "costume_suit-torso_aerial-suit"
local OTHER_TORSO_ID = "costume_suit-torso_agility-suit"
local ARM_ID = "costume_suit-left-arm_agility-suit"
local GLOVES_ID = "costume_accessories_gloves"
local PATTERN = "a-pattern"
local PRIMARY: TextureGroupKey = "Primary"
local SECONDARY: TextureGroupKey = "Secondary"
local DRAFT_COLOR = Color3.fromRGB(10, 20, 30)
local ROLL_COLOR = Color3.fromRGB(200, 100, 50)
-- Variables
-- References
-- Private Functions
local function newItem(definitionId: string, color: Color3, material: Enum.Material, pattern: string?): Item
	return {
		DefinitionId = definitionId,
		TextureGroups = {
			Primary = { Transparency = 0, Color = color, Material = material, Pattern = pattern },
			Secondary = { Transparency = 0, Color = color, Material = Enum.Material.SmoothPlastic },
		},
	}
end

local function find(character: Character, definitionId: string): Item?
	for _, item in character.Identities.Main.Appearance.Items do
		if item.DefinitionId == definitionId then
			return item
		end
	end
	return nil
end

-- yields nothing. the draft: a named hero of its own size in a patterned torso + gloves. the roll: somebody else
-- in another torso + an arm the draft never wore
local function merge()
	local draft = FreezeUtil.delta(CharacterConstructor.new(), function(t: Character): Character
		t.Id = "the-slot"
		t.Powers = { { Id = "a-power" } }
		local main = t.Identities.Main
		main.Profile.Name = "The Draft"
		main.Profile.Backstory = "was here first"
		main.Appearance.Scale = { Height = 1.2, Width = 1.1 }
		main.Appearance.SkinColor = DRAFT_COLOR
		main.Appearance.Items = {
			newItem(TORSO_ID, DRAFT_COLOR, Enum.Material.Metal, PATTERN),
			newItem(GLOVES_ID, DRAFT_COLOR, Enum.Material.Fabric, nil),
		}
		return t
	end)
	local roll = FreezeUtil.delta(CharacterConstructor.new(), function(t: Character): Character
		t.Powers = { { Id = "another-power" }, { Id = "a-third" } }
		local main = t.Identities.Main
		main.Profile.Name = "The Roll"
		main.Profile.Backstory = "was dealt"
		main.Appearance.Scale = { Height = 1, Width = 1 }
		main.Appearance.SkinColor = ROLL_COLOR
		main.Appearance.Items = {
			newItem(OTHER_TORSO_ID, ROLL_COLOR, Enum.Material.SmoothPlastic, nil),
			newItem(ARM_ID, ROLL_COLOR, Enum.Material.SmoothPlastic, nil),
		}
		return t
	end)
	local merged = RollUtil.merge(draft, roll)
	local isCharacter, msg = CharacterType.Character(merged)
	assert(isCharacter, `what came out isn't a character: {tostring(msg)}`)
	assert(table.isfrozen(merged), `what came out isn't frozen`)
	local main = merged.Identities.Main
	assert(merged.Id == "the-slot", `the draft lost its slot`)
	assert(SpecUtil.getIfEqual(main.Appearance.Scale, { Height = 1.2, Width = 1.1 }), `the body changed its size`)
	-- everything a roll writes is the roll's
	assert(main.Profile.Name == "The Roll" and main.Profile.Backstory == "was dealt", `the texts aren't the roll's`)
	assert(SpecUtil.getIfEqual(merged.Powers, roll.Powers), `the powers aren't the roll's`)
	assert(main.Appearance.SkinColor == ROLL_COLOR, `the skin isn't the roll's`)
	assert(find(merged, TORSO_ID) == nil, `the torso of the draft is still on`)
	-- the torso that was dealt wears the pattern + the material of the one before it, in its own color
	local torso = assert(find(merged, OTHER_TORSO_ID), `the torso that was dealt isn't on`)
	local primary = assert(torso.TextureGroups[PRIMARY], `the torso lost a group`)
	assert(primary.Pattern == PATTERN, `the pattern of the draft didn't carry over`)
	assert(primary.Material == Enum.Material.Metal, `the material of the draft didn't carry over`)
	assert(primary.Color == ROLL_COLOR, `the color isn't the roll's`)
	local secondary = assert(torso.TextureGroups[SECONDARY], `the torso lost a group`)
	assert(secondary.Pattern == nil, `a group without a pattern got one`)
	-- what the draft wore nothing of comes as it was dealt
	local arm = assert(find(merged, ARM_ID), `the arm that was dealt isn't on`)
	assert(SpecUtil.getIfEqual(arm, newItem(ARM_ID, ROLL_COLOR, Enum.Material.SmoothPlastic, nil)), `the arm changed`)
	-- a roll deals no accessory, the ones of the draft stay on as they were
	local gloves = assert(find(merged, GLOVES_ID), `the gloves of the draft came off`)
	assert(
		SpecUtil.getIfEqual(gloves, newItem(GLOVES_ID, DRAFT_COLOR, Enum.Material.Fabric, nil)),
		`the gloves changed`
	)
	assert(#main.Appearance.Items == 3, `the hero wears {#main.Appearance.Items} things`)
	-- neither of the two was written to
	assert(find(draft, TORSO_ID) ~= nil and find(roll, GLOVES_ID) == nil, `what went in was changed`)
end
-- Class
-- the items of the walk are one game's, + so is the button that rolls a draft
return GameDefinition.pick({
	shl1 = function(): TestMap
		return {}
	end,
	shl2 = function(): TestMap
		return {}
	end,
	shl3 = function(): TestMap
		return {
			Merge = SpecUtil.newScenario(merge),
		}
	end,
})
