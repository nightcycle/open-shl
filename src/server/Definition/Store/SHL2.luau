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
-- the version a save first said which game wrote it at
local STAMP_VERSION = 3
-- one entry per version that came before the current one: [1] takes a version 1 save to version 2
local MIGRATIONS: { (document: { [string]: any }) -> { [string]: any } } = table.freeze({
	-- a version 1 save listed the artifacts its player owned, every artifact is anybody's to wear since
	function(document: { [string]: any }): { [string]: any }
		document.ArtifactIds = nil
		return document
	end,
	-- a version 2 save didn't say which game wrote it, this was the only one there was to write it
	function(document: { [string]: any }): { [string]: any }
		document.Game = "shl2"
		return document
	end,
	-- a version 3 save said whether it had been through the import, not which pass of it. there was only the first
	function(document: { [string]: any }): { [string]: any }
		document.LegacyImportVersion = if document.IsLegacyImported then 1 else 0
		document.IsLegacyImported = nil
		return document
	end,
})
-- Variables
-- References
-- Private Functions
local function newPlayerSave(): PlayerSave
	local characters = CharacterSlotUtil.newStarters()
	local out: PlayerSave = {
		Version = SaveType.SHL2_VERSION,
		Game = "shl2",
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
		LegacyImportVersion = 0,
	}
	TableUtil.deepFreeze(out)
	return out
end
-- Class
-- the save of every player of the live game sits in this store under this key, a server that asks under another one
-- finds nothing. neither is ever changed, + the version only goes up together with a migration
return table.freeze({
	Name = "PlayerSave",
	GetKey = function(userId: number): string
		return `Player_{userId}`
	end,
	Version = SaveType.SHL2_VERSION,
	Validator = SaveType.SHL2PlayerSave,
	Default = newPlayerSave,
	Migrations = MIGRATIONS,
	StampVersion = STAMP_VERSION,
})
