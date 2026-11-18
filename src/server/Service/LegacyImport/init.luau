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
		-- whether there's a game before this one to ask. where there isn't no save is ever marked as asked for, so
		-- every one of them is still due the day the game gets its importer
		HasImporter: boolean,
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

return ServiceLocker(function(): LegacyImportService
	assert(DataService.IsInitialized, `the data service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		HasImporter = IMPORTER ~= nil,
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
