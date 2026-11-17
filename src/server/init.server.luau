--!strict
-- Services
-- Packages
-- Modules
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local BaseService = require("@game/ServerScriptService/Server/Service/Base")
local EconomyService = require("@game/ServerScriptService/Server/Service/Economy")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local ProfileService = require("@game/ServerScriptService/Server/Service/Profile")
local QuestService = require("@game/ServerScriptService/Server/Service/Quest")
local RoleplayService = require("@game/ServerScriptService/Server/Service/Roleplay")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
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

assert(not SessionService.IsInitialized, `the session service is already initialized`)
table.insert(DestroyCallbacks, SessionService.init())

assert(not AvatarService.IsInitialized, `the avatar service is already initialized`)
table.insert(DestroyCallbacks, AvatarService.init())

assert(not RoleplayService.IsInitialized, `the roleplay service is already initialized`)
table.insert(DestroyCallbacks, RoleplayService.init())

assert(not EconomyService.IsInitialized, `the economy service is already initialized`)
table.insert(DestroyCallbacks, EconomyService.init())

assert(not BaseService.IsInitialized, `the base service is already initialized`)
table.insert(DestroyCallbacks, BaseService.init())

assert(not QuestService.IsInitialized, `the quest service is already initialized`)
table.insert(DestroyCallbacks, QuestService.init())

assert(not ProfileService.IsInitialized, `the profile service is already initialized`)
table.insert(DestroyCallbacks, ProfileService.init())

game:BindToClose(function()
	for index = #DestroyCallbacks, 1, -1 do
		DestroyCallbacks[index]()
	end
end)
