--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local LegacyImportType = require("@game/ServerScriptService/Server/Type/LegacyImport")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type PlayerSave = SaveType.PlayerSave
type SavePatch = LegacyImportType.SavePatch

local Types = {}

-- the part of a session that's one game's own: what only it keeps of a player is only its to bring over. the session
-- service does what every game shares + hands the rest to the one of its game
export type SessionSection = {
	-- what the importer of the game may hand over: a patch that isn't one is turned down before any of it is in a save
	Patch: (value: unknown) -> (boolean, string?),
	-- writes a patch into a save that's open for it. how the two meet is the game's own to say: what takes the place of
	-- what, + what's kept of a save that was played before the importer got to it. it can't yield
	Import: (save: PlayerSave, patch: SavePatch) -> (),
}
Types.SessionSection = Type.strictInterface({
	Patch = Type.callback,
	Import = Type.callback,
})

return Types
