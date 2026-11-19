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
-- a save of this game said which game wrote it from the first one on, one that doesn't is another game's
local STAMP_VERSION = 1
-- one entry per version that came before the current one. the game is at its first: no save of it is kept yet, so
-- until it's given its universe what it keeps is changed in place + there's nothing to catch up
local MIGRATIONS: { (document: { [string]: any }) -> { [string]: any } } = table.freeze({})
-- Variables
-- References
-- Private Functions
-- what the game has no use for yet (a base, its furniture, the tutorial, a daily reward) is kept the way it starts out
local function newPlayerSave(): PlayerSave
	local characters = CharacterSlotUtil.newStarters()
	local out: PlayerSave = {
		Version = SaveType.SHL3_VERSION,
		Game = "shl3",
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
-- the store + the key every game of this code saves under. a data store belongs to a universe + each game is one, so
-- no other game finds these unless a place ends up in the wrong one
return table.freeze({
	Name = "PlayerSave",
	GetKey = function(userId: number): string
		return `Player_{userId}`
	end,
	Version = SaveType.SHL3_VERSION,
	Validator = SaveType.SHL3PlayerSave,
	Default = newPlayerSave,
	Migrations = MIGRATIONS,
	StampVersion = STAMP_VERSION,
})
