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
-- whatever the patch holds takes the place of what a new save starts out with. the importer of this game is at its
-- first version, so a save that's due it was never played: a first visit that can't ask the old stores ends in a kick
local function import(save: PlayerSave, patch: SavePatch)
	save.Characters = patch.Characters or save.Characters
	save.ActiveCharacterId = patch.ActiveCharacterId or save.ActiveCharacterId
	save.Balances = patch.Balances or save.Balances
	save.Inventory = patch.Inventory or save.Inventory
	save.BaseLayout = patch.BaseLayout or save.BaseLayout
	save.LastDailyRewardAt = patch.LastDailyRewardAt or save.LastDailyRewardAt
	if patch.IsTutorialEnabled ~= nil then
		save.IsTutorialEnabled = patch.IsTutorialEnabled
	end
end
-- Class
-- superhero life 2 keeps nothing in a section: what's its own was in the save before a game had one + stays there
local Section: SessionSection = table.freeze({
	Patch = LegacyImportType.SHL2SavePatch,
	Import = import,
})

return Section
