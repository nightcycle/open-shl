--!strict
-- Services
-- Packages
-- Modules
local DataService = require("@game/ServerScriptService/Server/Service/Data")
local FakeDataStoreUtil = require("@game/ServerScriptService/Server/Util/FakeDataStore")
local LegacyImportService = require("@game/ServerScriptService/Server/Service/LegacyImport")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
-- Types
-- Constants
-- nobody who's in a play-test
local USER_ID = 1
-- Variables
-- References
-- Private Functions
local function startData(): () -> ()
	assert(not DataService.IsInitialized, `the data service is already initialized`)
	return DataService.init()
end

local function startLegacyImport(): () -> ()
	assert(not LegacyImportService.IsInitialized, `the legacy import service is already initialized`)
	return LegacyImportService.init()
end
-- Class
return {
	-- the game has no importer yet: nobody can be asked what they had in the game before it, + nothing says they
	-- were. an answer of "nothing" would be taken for an import that's done
	NoImporter = SpecUtil.newScenario(function()
		local destroyCallbacks: { () -> () } = {}
		local success, msg = pcall(function()
			table.insert(destroyCallbacks, startData())
			assert(DataService.IsInitialized, `the data service isn't initialized`)
			local fake = FakeDataStoreUtil.new()
			DataService:SetDataStoreService(fake)
			table.insert(destroyCallbacks, startLegacyImport())
			assert(LegacyImportService.IsInitialized, `the legacy import service isn't initialized`)
			assert(not LegacyImportService.HasImporter, `the game has an importer, this spec is out of date`)
			local patchRes = LegacyImportService:Import(USER_ID)
			assert(patchRes.IsErr, `a patch was made with no game to import from`)
			assert(#fake:GetCalls() == 0, `a store was asked with no game to import from`)
		end)
		for index = #destroyCallbacks, 1, -1 do
			destroyCallbacks[index]()
		end
		if not success then
			error(msg, 0)
		end
	end),
}
