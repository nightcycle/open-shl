--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
local Parameter = SimpleTest.Parameter
-- Modules
local AccessDefinition = require("@game/ReplicatedStorage/Shared/Definition/Access")
local AppearanceConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance")
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local CharacterSlotUtil = require("@game/ServerScriptService/Server/Util/CharacterSlot")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
type Character = CharacterType.Character
type Owned = EconomyType.Owned
type Identity = IdentityType.Identity
-- Constants
-- a roll is different every time, so it's held to what's true of every one of them often enough to meet the rare ones
local ROLL_COUNT = 256
local MAX_NAME_LENGTH = CharacterEditorDefinition.MAX_NAME_LENGTH
local MAX_BACKSTORY_LENGTH = CharacterEditorDefinition.MAX_BACKSTORY_LENGTH
-- a cape + a power that have to be bought
local CAPE_ID = "costume_capes_jetpack"
local POWER_ID = "special_invisibility"
-- Variables
-- References
-- Private Functions
local function getLength(text: string): number
	return utf8.len(text) or math.huge
end

-- what the editor would hand back if the player saved the character untouched
local function assertPlayable(character: Character)
	local isValid, msg = CharacterType.Character(character)
	assert(isValid, `what was dealt isn't a character: {msg}`)
	assert(table.isfrozen(character), `the character isn't frozen`)
	assert(#character.Powers > 0, `the character has no power`)
	assert(#character.Powers <= PowerDefinition.DEFAULT_LIMIT, `the character holds {#character.Powers} powers`)
	for index, power in character.Powers do
		assert(PowerDefinition.get(power.Id).IsOk, `the game has no power "{power.Id}"`)
		for otherIndex = 1, index - 1 do
			assert(character.Powers[otherIndex].Id ~= power.Id, `the power "{power.Id}" is held twice`)
		end
	end
	local secret = character.Identities.Secret
	assert(secret, `the character has no secret identity`)
	local identities: { [string]: Identity } = { Main = character.Identities.Main, Secret = secret }
	for key, identity in identities do
		local name, backstory = identity.Profile.Name, identity.Profile.Backstory
		assert(name ~= "" and getLength(name) <= MAX_NAME_LENGTH, `the {key} name "{name}" doesn't fit`)
		assert(
			backstory ~= "" and getLength(backstory) <= MAX_BACKSTORY_LENGTH,
			`the {key} backstory of {getLength(backstory)} doesn't fit`
		)
		assert(#identity.Appearance.Items > 0, `the {key} identity wears nothing`)
		-- an item the library doesn't have, a second one of a kind or a group its item lacks would be dropped here
		assert(
			SpecUtil.getIfEqual(AppearanceConstructor.fix(identity.Appearance), identity.Appearance),
			`the {key} look doesn't make it through a save as it was dealt`
		)
	end
	assert(
		character.Identities.Main.Appearance.SkinColor == secret.Appearance.SkinColor,
		`the two identities aren't one person`
	)
end

local function getIfWorn(character: Character, itemId: string): boolean
	for _, item in character.Identities.Main.Appearance.Items do
		if item.DefinitionId == itemId then
			return true
		end
	end
	return false
end

local function getIfHeld(character: Character, powerId: string): boolean
	for _, power in character.Powers do
		if power.Id == powerId then
			return true
		end
	end
	return false
end
-- Class
return {
	-- what's dealt is what its player has: a piece or a power that has to be bought only ever comes up for somebody
	-- who bought it, + it does come up for them
	Owned = SpecUtil.newScenario(function()
		local nothing: Owned = { ItemIds = {}, PowerIds = {} }
		local some: Owned = { ItemIds = { CAPE_ID }, PowerIds = { POWER_ID } }
		assert(not AccessDefinition.getIfOwned(nothing, CAPE_ID), `the cape of the walk is anybody's`)
		assert(not AccessDefinition.getIfOwned(nothing, POWER_ID), `the power of the walk is anybody's`)
		local isCapeDealt, isPowerDealt = false, false
		for _ = 1, ROLL_COUNT do
			local rollRes = CharacterSlotUtil.roll(nothing)
			assert(rollRes.IsOk, `nobody was dealt: {tostring(rollRes.Value)}`)
			assert(rollRes.Value.Id == "", `a roll came with an id, it's nobody's slot yet`)
			assert(
				#AccessDefinition.getUnowned(rollRes.Value, nothing) == 0,
				`a new player was dealt what has to be bought`
			)
			local ownedRes = CharacterSlotUtil.roll(some)
			assert(ownedRes.IsOk, `nobody was dealt: {tostring(ownedRes.Value)}`)
			assertPlayable(FreezeUtil.delta(ownedRes.Value, function(t: Character): Character
				t.Id = "a-slot"
				return t
			end))
			assert(#AccessDefinition.getUnowned(ownedRes.Value, some) == 0, `somebody was dealt what they didn't buy`)
			isCapeDealt = isCapeDealt or getIfWorn(ownedRes.Value, CAPE_ID)
			isPowerDealt = isPowerDealt or getIfHeld(ownedRes.Value, POWER_ID)
		end
		assert(isCapeDealt, `a cape that was bought never came up`)
		assert(isPowerDealt, `a power that was bought never came up`)
		-- a slot a pass adds later is dealt the same way
		local blank = CharacterSlotUtil.newBlank(some)
		assert(#AccessDefinition.getUnowned(blank, some) == 0, `a later slot holds what its player didn't buy`)
	end),

	-- a slot that's added later holds a character that's ready to play
	Roll = SimpleTest.Test.new({ Parameter.Integer.new("Roll", 1, ROLL_COUNT) }, function(_roll: number): boolean
		local character = CharacterSlotUtil.newBlank()
		assert(character.Id ~= "", `the character has no id`)
		assertPlayable(character)
		return true
	end, ROLL_COUNT + 1),

	-- a new player finds every slot they have filled, each with somebody else
	Starters = SpecUtil.newScenario(function()
		local characters = CharacterSlotUtil.newStarters()
		assert(table.isfrozen(characters), `the starters aren't frozen`)
		assert(
			#characters == ProductDefinition.getCharacterSlotCount({}),
			`a new player is dealt {#characters} characters`
		)
		for index, character in characters do
			assert(character.Id ~= "", `starter {index} has no id`)
			for otherIndex = 1, index - 1 do
				assert(characters[otherIndex].Id ~= character.Id, `starters {otherIndex} + {index} share an id`)
			end
			assertPlayable(character)
		end
		-- two players don't start out with the same slots
		assert(CharacterSlotUtil.newStarters()[1].Id ~= characters[1].Id, `two players share the id of a slot`)
	end),
}
