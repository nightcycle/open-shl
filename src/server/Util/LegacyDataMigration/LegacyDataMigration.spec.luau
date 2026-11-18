--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Parameter = SimpleTest.Parameter
-- Modules
local BaseConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Base")
local FurnitureDefinition = require("@game/ReplicatedStorage/Shared/Definition/Furniture")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local LegacyDataMigration = require("@game/ServerScriptService/Server/Util/LegacyDataMigration")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
local ThemeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Theme")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Character = CharacterType.Character
-- Constants
-- what the old game stored in place of a slot or an identity that wasn't there
local NOTHING = "None"
local MAX_SLOT_COUNT = ProductDefinition.getCharacterSlotCount({ "ExtraCharacterSlots" })
local PAD_HEIGHT_OFFSET = FurnitureDefinition.PLACEMENT.PAD_HEIGHT_OFFSET
-- the 12 numbers of a CFrame the way a piece of a base was stored: in the middle of its pad, a few studs up
local PIECE_COMPONENTS = table.freeze({ 0, 5, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1 })
-- Variables
local OutfitNames: { string } = {}
-- References
local StarterSuits = IndexUtil.waitForPath("game/ServerScriptService/Data/legacy/starter-suits") :: Folder
local Outfits = IndexUtil.waitForPath("game/ServerScriptService/Data/legacy/outfit") :: Folder
-- Private Functions
-- a copy, the module of a fixture is shared with whoever else requires it
local function read(folder: Folder, name: string): { any }
	local module = folder:FindFirstChild(name)
	assert(module and module:IsA("ModuleScript"), `{folder.Name} has no "{name}"`)
	-- required by instance, rojo turns each json into a module
	return TableUtil.deepCopy(require(module) :: any)
end

local function readCharacter(suitIndex: number): Character
	local characterRes = LegacyDataMigration.toCharacter(read(StarterSuits, `Suit{suitIndex}`))
	assert(characterRes.IsOk, `starter suit {suitIndex} wasn't converted: {tostring(characterRes.Value)}`)
	return characterRes.Value
end

-- a starter suit is the two identities of a slot, a save has the id of the slot in front of them
local function newSlot(id: string, suitIndex: number): { unknown }
	local suit = read(StarterSuits, `Suit{suitIndex}`)
	return { id, suit[1], suit[2] }
end

local function getIds(characters: { Character }): { string }
	local out: { string } = {}
	for index, character in characters do
		out[index] = character.Id
	end
	return out
end

for _, module in Outfits:GetChildren() do
	table.insert(OutfitNames, module.Name)
end
table.sort(OutfitNames)
table.freeze(OutfitNames)
-- Class
return {
	-- every suit a new player starts out with makes it over whole, without the fixture being written to
	StarterSuit = SimpleTest.Test.new(
		{ Parameter.Integer.new("Suit", 1, #StarterSuits:GetChildren()) },
		function(suitIndex: number): boolean
			local suit = read(StarterSuits, `Suit{suitIndex}`)
			local copy = TableUtil.deepCopy(suit)
			local characterRes = LegacyDataMigration.toCharacter(suit)
			assert(characterRes.IsOk, `it wasn't converted: {tostring(characterRes.Value)}`)
			local character = characterRes.Value
			local isValid, msg = CharacterType.Character(character)
			assert(isValid, `what came out isn't a character: {msg}`)
			assert(table.isfrozen(character), `the character isn't frozen`)
			assert(character.Id ~= "", `the character has no id`)
			assert(#character.Powers == #suit[2][1][1], `a power was lost on the way`)
			local secret = character.Identities.Secret
			assert(secret, `the character has no secret identity`)
			assert(character.Identities.Main.Profile.Name == suit[2][2][2], `the name of the hero is off`)
			assert(secret.Profile.Name == suit[1][2][2], `the name of the secret identity is off`)
			-- an identity is its shared values, its texts + its skin, every entry past those is an item
			assert(#character.Identities.Main.Appearance.Items == #suit[2] - 3, `the hero lost an item on the way`)
			assert(#secret.Appearance.Items == #suit[1] - 3, `the secret identity lost an item on the way`)
			assert(SpecUtil.getIfEqual(suit, copy), `the fixture was written to`)
			return SpecUtil.getIfEqual(readCharacter(suitIndex), character)
		end,
		#StarterSuits:GetChildren() + 1
	),

	-- the first starter suit, down to what it holds
	FirstStarterSuit = SpecUtil.newScenario(function()
		local character = readCharacter(1)
		assert(character.Id == "83659917629631391333", `the id is "{character.Id}"`)
		assert(
			SpecUtil.getIfEqual(character.Powers, {
				{ Id = "basic-melee_martial-arts" },
				{ Id = "transportation_flight" },
				{ Id = "ranged_laser-hand" },
				{ Id = "transportation_wall-climb" },
			}),
			`the powers are off`
		)
		local main, secret = character.Identities.Main, character.Identities.Secret
		assert(secret, `the character has no secret identity`)
		assert(main.Profile.Name == "Red Rage", `the hero is called "{main.Profile.Name}"`)
		assert(main.Profile.Alignment == "ChaoticGood", `the hero is {main.Profile.Alignment}`)
		assert(string.find(main.Profile.Backstory, "^Some people get angry"), `the backstory of the hero is off`)
		assert(secret.Profile.Name == "Chad Muller", `the secret identity is called "{secret.Profile.Name}"`)
		-- stored as the code the old game had for a text that was never written
		assert(secret.Profile.Backstory == "", `the secret identity has a backstory`)
		assert(main.Appearance.SkinColor == BrickColor.new("Pastel brown").Color, `the skin color is off`)
		assert(#main.Appearance.HiddenTags == 0, `the hero hides something`)
	end),

	-- every piece of every uniform is an item the game still has
	Outfit = SimpleTest.Test.new({ Parameter.Choose.new("Outfit", OutfitNames) }, function(name: string): boolean
		local outfit = read(Outfits, name)
		local copy = TableUtil.deepCopy(outfit)
		local outfitRes = LegacyDataMigration.convertOutfit(outfit)
		assert(outfitRes.IsOk, `it wasn't converted: {tostring(outfitRes.Value)}`)
		assert(#outfitRes.Value.Items == #outfit, `an item was lost on the way`)
		for _, item in outfitRes.Value.Items do
			assert(ItemAppearanceDefinition.get(item.Name).IsOk, `"{item.Name}" isn't an item`)
			assert(item.Primary, `"{item.Name}" lost its color`)
		end
		return SpecUtil.getIfEqual(outfit, copy)
	end, #OutfitNames + 1),

	-- a save is never turned down as a whole over a part of it
	Slots = SpecUtil.newScenario(function()
		local characters, problems = LegacyDataMigration.toCharacters({
			newSlot("slot-a", 1),
			NOTHING,
			{ "slot-c", NOTHING, NOTHING },
			newSlot("slot-d", 2),
			newSlot("slot-a", 3),
			newSlot("", 3),
			12,
		} :: { unknown })
		-- the id of a slot is the one it's stored under, the copies in its identities can be behind
		assert(SpecUtil.getIfEqual(getIds(characters), { "slot-a", "slot-d" }), `the wrong slots made it over`)
		assert(characters[1].Identities.Main.Profile.Name == "Red Rage", `the first slot isn't the first suit`)
		assert(characters[2].Identities.Main.Profile.Name == "Snow Sister", `the fourth slot isn't the second suit`)
		assert(#problems == 5, `{#problems} slots were said to be left out`)
		for index, slotIndex in { 2, 3, 5, 6, 7 } do
			assert(string.find(problems[index], `^slot {slotIndex}: `), `nothing is said about slot {slotIndex}`)
		end

		-- json has null where a list had a hole
		local holed: { [number]: unknown } = { [1] = newSlot("slot-a", 1), [3] = newSlot("slot-c", 2) }
		characters, problems = LegacyDataMigration.toCharacters(holed)
		assert(SpecUtil.getIfEqual(getIds(characters), { "slot-a", "slot-c" }), `a hole cost a save its slots`)
		assert(#problems == 1, `{#problems} slots were said to be left out of a list with one hole`)

		-- a slot the old game added for the slots pass could lose its two styles on its way through a client
		local short = newSlot("slot-a", 1)
		for index = 2, 3 do
			local shared = (short[index] :: { any })[1]
			shared[5] = nil
			shared[4] = nil
		end
		characters, problems = LegacyDataMigration.toCharacters({ short })
		assert(#characters == 1 and #problems == 0, `a slot without its styles was left out: {problems[1]}`)

		local many: { unknown } = {}
		for index = 1, MAX_SLOT_COUNT + 1 do
			many[index] = newSlot(`slot-{index}`, 1)
		end
		characters, problems = LegacyDataMigration.toCharacters(many)
		assert(#characters == MAX_SLOT_COUNT, `a save came out with {#characters} slots`)
		assert(#problems == 1, `the slot past the last one wasn't said to be left out`)

		characters, problems = LegacyDataMigration.toCharacters({})
		assert(#characters == 0 and #problems == 0, `a save without slots didn't come out empty`)
	end),

	-- the old game kept one worn artifact per player, here it's an item of the hero that wears it
	WornArtifact = SpecUtil.newScenario(function()
		local artifact = ItemAppearanceDefinition.list("costume", "artifacts")[1]
		assert(artifact and artifact.Name, `the game has no artifact with a name`)
		local character = readCharacter(1)
		local itemCount = #character.Identities.Main.Appearance.Items

		local bareRes = LegacyDataMigration.wearArtifact(character, { NOTHING, true, true, true, true })
		assert(bareRes.IsOk and bareRes.Value == character, `wearing no artifact changed the character`)

		-- hair, masks, hoods + mouth covers: whatever wasn't left showing is hidden
		local wornRes = LegacyDataMigration.wearArtifact(character, { artifact.Name, true, false, true, false })
		assert(wornRes.IsOk, `the artifact wasn't put on: {tostring(wornRes.Value)}`)
		local appearance = wornRes.Value.Identities.Main.Appearance
		assert(#appearance.Items == itemCount + 1, `the hero doesn't wear one item more`)
		assert(appearance.Items[itemCount + 1].DefinitionId == artifact.Id, `the last item isn't the artifact`)
		assert(SpecUtil.getIfEqual(appearance.HiddenTags, { "Mask", "MouthCover" }), `the wrong items are hidden`)
		local isValid, msg = CharacterType.Character(wornRes.Value)
		assert(isValid, `a hero that wears an artifact isn't a character: {msg}`)
		assert(#character.Identities.Main.Appearance.Items == itemCount, `the character it was handed was written to`)

		local missingRes = LegacyDataMigration.wearArtifact(character, { "Spec Of Dust", true, true, true, true })
		assert(missingRes.IsErr, `an artifact the game doesn't have was put on`)
	end),

	-- the old game kept the furniture + the themes a player bought in one list + didn't ask if a piece was owned
	Base = SpecUtil.newScenario(function()
		local furniture, otherFurniture = FurnitureDefinition.list()[1], FurnitureDefinition.list()[2]
		local theme: ThemeDefinition.ThemeDefinition? = nil
		for _, definition in ThemeDefinition.list() do
			if definition.Id ~= ThemeDefinition.DEFAULT_ID then
				theme = definition
				break
			end
		end
		assert(furniture and otherFurniture and theme, `the game is short of furniture or themes`)

		local inventory, problems = LegacyDataMigration.toInventory({
			furniture.Name,
			theme.Name,
			furniture.Name,
			"Spec Of Dust",
		})
		assert(SpecUtil.getIfEqual(inventory.FurnitureIds, { furniture.Id }), `the furniture that's owned is off`)
		assert(
			SpecUtil.getIfEqual(inventory.ThemeIds, { ThemeDefinition.DEFAULT_ID, theme.Id }),
			`the themes that are owned are off`
		)
		assert(#problems == 1 and string.find(problems[1], "^purchase 4: "), `the purchase that's left out is off`)
		assert(table.isfrozen(inventory), `the inventory isn't frozen`)

		local layout, layoutProblems = LegacyDataMigration.toBaseLayout(
			{
				theme.Name,
				"a title that was never used",
				{ 1 :: any, furniture.Name, PIECE_COMPONENTS },
				-- a save can hold the pad as a text
				{ "2" :: any, furniture.Name, PIECE_COMPONENTS },
				{ 9 :: any, furniture.Name, PIECE_COMPONENTS },
				{ 1 :: any, otherFurniture.Name, PIECE_COMPONENTS },
				{ 1 :: any, "Spec Of Dust", PIECE_COMPONENTS },
				NOTHING,
			} :: { unknown },
			inventory
		)
		assert(layout.ThemeId == theme.Id, `the base has the "{layout.ThemeId}" theme`)
		assert(#layout.Furniture == 2, `{#layout.Furniture} pieces made it over`)
		for index, piece in layout.Furniture do
			assert(piece.Id == `imported-{index}`, `piece {index} has the id "{piece.Id}"`)
			assert(
				piece.FurnitureId == furniture.Id and piece.ZoneId == index,
				`piece {index} isn't the one that was placed`
			)
			-- a piece stands on its pad, however high the old game left it
			assert(
				piece.CFrame == CFrame.new(0, PAD_HEIGHT_OFFSET, 0),
				`piece {index} doesn't stand where it was placed`
			)
		end
		assert(#layoutProblems == 4, `{#layoutProblems} pieces were said to be left out`)
		for index, pieceIndex in { 3, 4, 5, 6 } do
			assert(
				string.find(layoutProblems[index], `^piece {pieceIndex}: `),
				`nothing is said about piece {pieceIndex}`
			)
		end
		assert(table.isfrozen(layout), `the layout isn't frozen`)

		-- a theme that was put up without being bought stays behind
		local bareLayout, bareProblems =
			LegacyDataMigration.toBaseLayout({ theme.Name, "" } :: { unknown }, BaseConstructor.newInventory())
		assert(bareLayout.ThemeId == ThemeDefinition.DEFAULT_ID, `a theme that isn't owned was put up`)
		assert(#bareProblems == 1 and string.find(bareProblems[1], "^theme: "), `nothing is said about the theme`)
	end),
}
