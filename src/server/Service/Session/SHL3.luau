--!strict
-- Services
-- Packages
-- Modules
-- Types
local LegacyImportType = require("@game/ServerScriptService/Server/Type/LegacyImport")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
local SessionSectionType = require("@game/ServerScriptService/Server/Type/SessionSection")
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
	local section, own = save.SHL3, patch.SHL3
	assert(section, `a save of this game has its section`)
	if own then
		section.OwnedItemIds = own.OwnedItemIds or section.OwnedItemIds
		section.ApartmentTier = own.ApartmentTier or section.ApartmentTier
		section.RedeemedCodeIds = own.RedeemedCodeIds or section.RedeemedCodeIds
	end
end
-- Class
local Section: SessionSection = table.freeze({
	Patch = LegacyImportType.SHL3SavePatch,
	Import = import,
})

return Section
