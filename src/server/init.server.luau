--!strict
-- Services
-- Packages
-- Modules
local AbilityService = require("@game/ServerScriptService/Server/Service/Ability")
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local BeaconService = require("@game/ServerScriptService/Server/Service/Beacon")
local CharacterService = require("@game/ServerScriptService/Server/Service/Character")
local ColorizerService = require("@game/ServerScriptService/Server/Service/Colorizer")
local DataService = require("@game/ServerScriptService/Server/Service/Data")
local DayNightService = require("@game/ServerScriptService/Server/Service/DayNight")
local EconomyService = require("@game/ServerScriptService/Server/Service/Economy")
local GateService = require("@game/ServerScriptService/Server/Service/Gate")
local HazardService = require("@game/ServerScriptService/Server/Service/Hazard")
local LegacyImportService = require("@game/ServerScriptService/Server/Service/LegacyImport")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local ProfileService = require("@game/ServerScriptService/Server/Service/Profile")
local QuestService = require("@game/ServerScriptService/Server/Service/Quest")
local ReactorService = require("@game/ServerScriptService/Server/Service/Reactor")
local RebuildService = require("@game/ServerScriptService/Server/Service/Rebuild")
local ResidenceService = require("@game/ServerScriptService/Server/Service/Residence")
local RoleplayService = require("@game/ServerScriptService/Server/Service/Roleplay")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local UniformService = require("@game/ServerScriptService/Server/Service/Uniform")
local VFXService = require("@game/ServerScriptService/Server/Service/VFX")
-- Types
-- Constants
-- Variables
local DestroyCallbacks: { () -> () } = {}
-- References
-- Private Functions
-- Class
-- a service leans on the ones above it, so they start in this order + stop in the reverse one
assert(not NetworkService.IsInitialized, `the network service is already initialized`)
table.insert(DestroyCallbacks, NetworkService.init())

assert(not DataService.IsInitialized, `the data service is already initialized`)
table.insert(DestroyCallbacks, DataService.init())

assert(not LegacyImportService.IsInitialized, `the legacy import service is already initialized`)
table.insert(DestroyCallbacks, LegacyImportService.init())

assert(not SessionService.IsInitialized, `the session service is already initialized`)
table.insert(DestroyCallbacks, SessionService.init())

assert(not VFXService.IsInitialized, `the vfx service is already initialized`)
table.insert(DestroyCallbacks, VFXService.init())

assert(not AbilityService.IsInitialized, `the ability service is already initialized`)
table.insert(DestroyCallbacks, AbilityService.init())

assert(not AvatarService.IsInitialized, `the avatar service is already initialized`)
table.insert(DestroyCallbacks, AvatarService.init())

assert(not CharacterService.IsInitialized, `the character service is already initialized`)
table.insert(DestroyCallbacks, CharacterService.init())

assert(not RoleplayService.IsInitialized, `the roleplay service is already initialized`)
table.insert(DestroyCallbacks, RoleplayService.init())

assert(not EconomyService.IsInitialized, `the economy service is already initialized`)
table.insert(DestroyCallbacks, EconomyService.init())

assert(not ResidenceService.IsInitialized, `the residence service is already initialized`)
table.insert(DestroyCallbacks, ResidenceService.init())

assert(not QuestService.IsInitialized, `the quest service is already initialized`)
table.insert(DestroyCallbacks, QuestService.init())

assert(not ProfileService.IsInitialized, `the profile service is already initialized`)
table.insert(DestroyCallbacks, ProfileService.init())

assert(not DayNightService.IsInitialized, `the day night service is already initialized`)
table.insert(DestroyCallbacks, DayNightService.init())

assert(not BeaconService.IsInitialized, `the beacon service is already initialized`)
table.insert(DestroyCallbacks, BeaconService.init())

assert(not ColorizerService.IsInitialized, `the colorizer service is already initialized`)
table.insert(DestroyCallbacks, ColorizerService.init())

assert(not RebuildService.IsInitialized, `the rebuild service is already initialized`)
table.insert(DestroyCallbacks, RebuildService.init())

assert(not GateService.IsInitialized, `the gate service is already initialized`)
table.insert(DestroyCallbacks, GateService.init())

assert(not HazardService.IsInitialized, `the hazard service is already initialized`)
table.insert(DestroyCallbacks, HazardService.init())

assert(not ReactorService.IsInitialized, `the reactor service is already initialized`)
table.insert(DestroyCallbacks, ReactorService.init())

assert(not UniformService.IsInitialized, `the uniform service is already initialized`)
table.insert(DestroyCallbacks, UniformService.init())

game:BindToClose(function()
	for index = #DestroyCallbacks, 1, -1 do
		-- the data service writes every save as it stops, a service that throws on its way out can't be in its way
		local success, msg = pcall(DestroyCallbacks[index] :: any)
		if not success then
			warn(`destroy err: {msg}`)
		end
	end
end)
