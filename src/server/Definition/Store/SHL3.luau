--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BaseConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Base")
local CharacterSlotUtil = require("@game/ServerScriptService/Server/Util/CharacterSlot")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
-- Types
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type PlayerSave = SaveType.PlayerSave
-- Constants
-- one entry per version that came before the current one. no save of this game was ever written at version 1: its
-- saves are in the shape of the game this code was written for, which is at version 2, so the one step there is to
-- hand the document back as it is
local MIGRATIONS = table.freeze({
	function(document: { [string]: any }): { [string]: any }
		return document
	end,
})
-- Variables
-- References
-- Private Functions
-- what the game has no use for yet (a base, its furniture, the tutorial, a daily reward) is kept the way it starts out
local function newPlayerSave(): PlayerSave
	local characters = CharacterSlotUtil.newStarters()
	local out: PlayerSave = {
		Version = SaveType.CURRENT_VERSION,
		Characters = characters,
		ActiveCharacterId = characters[1].Id,
		Balances = ProductDefinition.STARTING_BALANCES,
		Inventory = BaseConstructor.newInventory(),
		Entitlements = {},
		BaseLayout = BaseConstructor.new(),
		IsApartmentLocked = AttributeDefinition.IsApartmentLocked.Default,
		IsTutorialEnabled = AttributeDefinition.IsTutorialEnabled.Default,
		LastDailyRewardAt = 0,
		PurchaseIds = {},
		IsLegacyImported = false,
	}
	TableUtil.deepFreeze(out)
	return out
end
-- Class
-- a store of its own: a place of this game that's opened in the universe of another finds none of its saves there, +
-- no other game finds these. the saves it holds so far are from before the game had a shape of its own to keep them in
return table.freeze({
	Name = "PlayerSave_shl3",
	GetKey = function(userId: number): string
		return `Player_{userId}`
	end,
	Version = SaveType.CURRENT_VERSION,
	Validator = SaveType.PlayerSave,
	Default = newPlayerSave,
	Migrations = MIGRATIONS,
})
