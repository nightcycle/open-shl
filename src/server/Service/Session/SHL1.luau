--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local LegacyImportType = require("@game/ServerScriptService/Server/Type/LegacyImport")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
local SessionSectionType = require("@game/ServerScriptService/Server/Type/SessionSection")
type Owned = EconomyType.Owned
type PlayerSave = SaveType.PlayerSave
type SavePatch = LegacyImportType.SavePatch
type SessionSection = SessionSectionType.SessionSection
-- Constants
-- Variables
-- References
-- Private Functions
-- whatever the patch holds takes the place of what the save holds, in what every game keeps + in the section of this
-- one. the game has no importer yet: the one that's written for it finds saves that were played before it, what of
-- theirs it may write over is settled here along with it
local function import(save: PlayerSave, patch: SavePatch)
	save.Characters = patch.Characters or save.Characters
	save.ActiveCharacterId = patch.ActiveCharacterId or save.ActiveCharacterId
	save.Balances = patch.Balances or save.Balances
	local section, own = save.SHL1, patch.SHL1
	assert(section, `a save of this game has its section`)
	if own then
		section.RentedItemIds = own.RentedItemIds or section.RentedItemIds
		-- a flag that's off is a value like any other, only one that isn't there leaves the save as it is
		if own.IsGroupPerkGranted ~= nil then
			section.IsGroupPerkGranted = own.IsGroupPerkGranted
		end
		if own.IsPeaceful ~= nil then
			section.IsPeaceful = own.IsPeaceful
		end
	end
end

-- nothing here is bought for good: what a save says of what the game holds back is whether its player was ever seen
-- in the group. the passes aren't the save's to say
local function getOwned(save: PlayerSave): Owned
	local section = save.SHL1
	assert(section, `a save of this game has its section`)
	return {
		ItemIds = {},
		PowerIds = {},
		HasGroupPerk = section.IsGroupPerkGranted,
	}
end

local function setAttributes(player: Player, save: PlayerSave)
	local section = save.SHL1
	assert(section, `a save of this game has its section`)
	AttributeDefinition.set(player, AttributeDefinition.HasGroupPerk, section.IsGroupPerkGranted)
end
-- Class
local Section: SessionSection = table.freeze({
	Patch = LegacyImportType.SHL1SavePatch,
	Import = import,
	SetAttributes = setAttributes,
	GetOwned = getOwned,
})

return Section
