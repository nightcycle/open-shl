--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local DataService = require("@game/ServerScriptService/Server/Service/Data")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local LegacyImportType = require("@game/ServerScriptService/Server/Type/LegacyImport")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Importer = LegacyImportType.Importer
export type SavePatch = LegacyImportType.SavePatch
type LegacyImportServiceImpl = {
	__index: LegacyImportServiceImpl,
	Import: (self: LegacyImportService, userId: number) -> Result<SavePatch, string>,
	GetIfDue: (self: LegacyImportService, importVersion: number) -> boolean,
}
export type LegacyImportService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- the version of the importer of this game, 0 where there's no game before it to ask. a save keeps the
		-- version of the pass it had: with no importer none is ever behind, so no save is marked as asked for + every
		-- one of them is still due the day the game gets its importer
		Version: number,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: LegacyImportServiceImpl
))
-- Constants
local isImporter = Type.optional(LegacyImportType.Importer)
-- the game a game takes over from is its own: the stores, what they hold + how that's turned into a save. none of
-- another game's is ever required. a game that takes over from nothing has no importer
local IMPORTER: Importer? = GameDefinition.pick({
	shl1 = function(): Importer?
		return nil
	end,
	shl2 = function(): Importer?
		return require("@self/SHL2")
	end,
	shl3 = function(): Importer?
		return nil
	end,
})
assert(isImporter(IMPORTER))
-- Variables
-- References
-- Private Functions
-- Class
local LegacyImportService = {} :: LegacyImportServiceImpl
LegacyImportService.__index = LegacyImportService

-- yields. a user the old stores hold nothing of gets an empty patch, an error means they couldn't be asked
function LegacyImportService:Import(userId: number): Result<SavePatch, string>
	-- with no game before this one there's nobody to ask. an empty patch would say they were asked + had nothing
	if not IMPORTER then
		return Result.err(`{GameDefinition.ID} has no game before it to import from`)
	end
	return IMPORTER.Import(userId)
end

-- whether a save that had the pass of that version (0 for none) is owed the one of the importer there is by now
function LegacyImportService:GetIfDue(importVersion: number): boolean
	return importVersion < self.Version
end

return ServiceLocker(function(): LegacyImportService
	assert(DataService.IsInitialized, `the data service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		Version = if IMPORTER then IMPORTER.Version else 0,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, LegacyImportService)
	return self
end, function(self: LegacyImportService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
