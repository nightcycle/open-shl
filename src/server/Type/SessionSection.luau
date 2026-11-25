--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
-- Components
-- Hooks
-- Types
local LegacyImportType = require("@game/ServerScriptService/Server/Type/LegacyImport")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Result<V, E> = TypeUnionLib.Result<V, E>
type PlayerSave = SaveType.PlayerSave
type SavePatch = LegacyImportType.SavePatch
type Snapshot = SessionType.Snapshot

local Types = {}

-- what the session service lets the part of it that's one game's own ask of it
export type Sessions = {
	-- the one way a save changes, as the service has it
	Update: (player: Player, fn: (save: PlayerSave) -> PlayerSave?) -> Result<PlayerSave, string>,
}
Types.Sessions = Type.strictInterface({
	Update = Type.callback,
})

-- the part of a session that's one game's own: what only it keeps of a player is only its to bring over, to hand to
-- a client + to take requests for. the session service does what every game shares + hands the rest to the one of
-- its game. a game names the last four only where it has something of its own to say
export type SessionSection = {
	-- what the importer of the game may hand over: a patch that isn't one is turned down before any of it is in a save
	Patch: (value: unknown) -> (boolean, string?),
	-- writes a patch into a save that's open for it. how the two meet is the game's own to say: what takes the place of
	-- what, + what's kept of a save that was played before the importer got to it. it can't yield
	Import: (save: PlayerSave, patch: SavePatch) -> (),
	-- adds what only this game keeps to what a client is handed of its session as it asks. it can't yield
	Snapshot: ((snapshot: Snapshot, save: PlayerSave) -> ())?,
	-- writes the scalars of a save only this game has a client read, right after the ones of every game
	SetAttributes: ((player: Player, save: PlayerSave) -> ())?,
	-- sends on what changed in a save of what only this game hands a client, right after what every game sends
	Replicate: ((player: Player, save: PlayerSave, priorSave: PlayerSave) -> ())?,
	-- runs as the service starts, for the requests only this game takes. what it hands back undoes it
	Start: ((sessions: Sessions) -> (() -> ())?)?,
}
Types.SessionSection = Type.strictInterface({
	Patch = Type.callback,
	Import = Type.callback,
	Snapshot = Type.optional(Type.callback),
	SetAttributes = Type.optional(Type.callback),
	Replicate = Type.optional(Type.callback),
	Start = Type.optional(Type.callback),
})

return Types
