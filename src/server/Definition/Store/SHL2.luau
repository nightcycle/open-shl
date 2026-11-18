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
-- one entry per version that came before the current one: [1] takes a version 1 save to version 2
local MIGRATIONS = table.freeze({
	-- a version 1 save listed the artifacts its player owned, every artifact is anybody's to wear since
	function(document: { [string]: any }): { [string]: any }
		document.ArtifactIds = nil
		return document
	end,
})
-- Variables
-- References
-- Private Functions
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
-- the save of every player of the live game sits in this store under this key, a server that asks under another one
-- finds nothing. neither is ever changed, + the version only goes up together with a migration
return table.freeze({
	Name = "PlayerSave",
	GetKey = function(userId: number): string
		return `Player_{userId}`
	end,
	Version = SaveType.CURRENT_VERSION,
	Validator = SaveType.PlayerSave,
	Default = newPlayerSave,
	Migrations = MIGRATIONS,
})
