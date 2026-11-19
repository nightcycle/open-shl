--!strict
-- Services
-- Packages
-- Modules
local AppearanceConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance")
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local CharacterSlotUtil = require("@game/ServerScriptService/Server/Util/CharacterSlot")
local PaletteUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/Palette")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
type Character = CharacterType.Character
type Identity = IdentityType.Identity
-- Constants
-- Variables
-- References
-- Private Functions
-- a slot nobody made a character in yet: the name of its hero is empty, which is what says so. it's a character all
-- the same, the editor opens on it + the server takes it back the way it was handed out
local function assertEmpty(character: Character)
	local isValid, msg = CharacterType.Character(character)
	assert(isValid, `the slot doesn't hold a character: {msg}`)
	assert(table.isfrozen(character), `the character isn't frozen`)
	assert(#character.Powers == 0, `an empty slot holds {#character.Powers} powers`)
	assert(PowerDefinition.getLoadoutError({}, PowerDefinition.DEFAULT_LIMIT) == nil, `no power at all isn't a loadout`)
	local main, secret = character.Identities.Main, character.Identities.Secret
	assert(secret, `the character has no secret identity`)
	local identities: { [string]: Identity } = { Main = main, Secret = secret }
	for key, identity in identities do
		assert(identity.Profile.Name == "", `the {key} identity of an empty slot is named "{identity.Profile.Name}"`)
		assert(identity.Profile.Backstory == "", `the {key} identity of an empty slot has a backstory`)
		-- the side the old creator showed before anybody picked one
		assert(
			identity.Profile.Alignment == "NeutralGood",
			`the {key} identity starts out {identity.Profile.Alignment}`
		)
		assert(#identity.Appearance.Items == 0, `the {key} identity of an empty slot wears something`)
		assert(
			CharacterEditorDefinition.getPaletteColor(identity.Appearance.SkinColor) ~= nil,
			`the skin of the {key} identity isn't a color of the game`
		)
		-- neither what the library lacks nor a color off the palette is in it for a save to take out
		assert(
			SpecUtil.getIfEqual(PaletteUtil.apply(AppearanceConstructor.fix(identity.Appearance)), identity.Appearance),
			`the {key} look doesn't make it through a save as it was handed out`
		)
	end
	assert(main.Appearance.SkinColor == secret.Appearance.SkinColor, `the two identities aren't one person`)
end
-- Class
return {
	-- a slot that's added later is an empty one
	Blank = SpecUtil.newScenario(function()
		local character = CharacterSlotUtil.newBlank()
		assert(character.Id ~= "", `the character has no id`)
		assertEmpty(character)
		assert(CharacterSlotUtil.newBlank().Id ~= character.Id, `two slots share an id`)
	end),

	-- a new player finds every row the old game saved to, each of them empty
	Starters = SpecUtil.newScenario(function()
		local characters = CharacterSlotUtil.newStarters()
		assert(table.isfrozen(characters), `the starters aren't frozen`)
		assert(#characters == ProductDefinition.getCharacterSlotCount({}), `a new player is handed {#characters} slots`)
		assert(#characters == 5, `the old game saved to five rows, a new player has {#characters}`)
		for index, character in characters do
			assert(character.Id ~= "", `starter {index} has no id`)
			for otherIndex = 1, index - 1 do
				assert(characters[otherIndex].Id ~= character.Id, `starters {otherIndex} + {index} share an id`)
			end
			assertEmpty(character)
		end
		-- two players don't start out with the same slots
		assert(CharacterSlotUtil.newStarters()[1].Id ~= characters[1].Id, `two players share the id of a slot`)
	end),
}
