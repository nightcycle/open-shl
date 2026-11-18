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
}
export type LegacyImportService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
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
	-- with no game before this one there's nothing anybody could have had in it
	if not IMPORTER then
		local patch: SavePatch = {}
		table.freeze(patch)
		return Result.ok(patch)
	end
	return IMPORTER.Import(userId)
end

return ServiceLocker(function(): LegacyImportService
	assert(DataService.IsInitialized, `the data service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
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
