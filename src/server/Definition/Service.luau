--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local ServiceType = require("@game/ReplicatedStorage/Shared/Type/Service")
type Service = ServiceLocker.InitializationInterface
export type Entry = ServiceType.Entry
-- Constants
local FEATURES = GameDefinition.FEATURES
-- a service leans on the ones above it, so they start in this order + stop in the reverse one. one that isn't this
-- game's is never required, so whatever it waits on doesn't have to be in the place
local ENTRIES: { Entry } = {
	{
		Name = "Network",
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Network")
			assert(not service.IsInitialized, `the network service is already initialized`)
			return service
		end,
	},
	-- a private server finds out what it plays by in here, so nothing that asks about it starts before this is back
	{
		Name = "CustomServer",
		IsFeatured = FEATURES.CustomServers,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/CustomServer")
			assert(not service.IsInitialized, `the custom server service is already initialized`)
			return service
		end,
	},
	-- a client makes up its mind about the mode screen as soon as it's in, so this is on before the saves are
	{
		Name = "ModeSelect",
		IsFeatured = FEATURES.ModeSelect,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/ModeSelect")
			assert(not service.IsInitialized, `the mode select service is already initialized`)
			return service
		end,
	},
	{
		Name = "Data",
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Data")
			assert(not service.IsInitialized, `the data service is already initialized`)
			return service
		end,
	},
	{
		Name = "LegacyImport",
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/LegacyImport")
			assert(not service.IsInitialized, `the legacy import service is already initialized`)
			return service
		end,
	},
	{
		Name = "Session",
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Session")
			assert(not service.IsInitialized, `the session service is already initialized`)
			return service
		end,
	},
	{
		Name = "VFX",
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/VFX")
			assert(not service.IsInitialized, `the vfx service is already initialized`)
			return service
		end,
	},
	{
		Name = "Ability",
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Ability")
			assert(not service.IsInitialized, `the ability service is already initialized`)
			return service
		end,
	},
	{
		Name = "Avatar",
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Avatar")
			assert(not service.IsInitialized, `the avatar service is already initialized`)
			return service
		end,
	},
	{
		Name = "Character",
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Character")
			assert(not service.IsInitialized, `the character service is already initialized`)
			return service
		end,
	},
	-- who fights + who sits it out, where that's each player's own pick: an avatar says which from the moment it's in
	{
		Name = "PlayerMode",
		IsFeatured = FEATURES.PlayerMode,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/PlayerMode")
			assert(not service.IsInitialized, `the player mode service is already initialized`)
			return service
		end,
	},
	{
		Name = "Roleplay",
		IsFeatured = FEATURES.Roleplay,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Roleplay")
			assert(not service.IsInitialized, `the roleplay service is already initialized`)
			return service
		end,
	},
	{
		Name = "Economy",
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Economy")
			assert(not service.IsInitialized, `the economy service is already initialized`)
			return service
		end,
	},
	{
		Name = "Residence",
		IsFeatured = FEATURES.Residences,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Residence")
			assert(not service.IsInitialized, `the residence service is already initialized`)
			return service
		end,
	},
	{
		Name = "Quest",
		IsFeatured = FEATURES.Quests,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Quest")
			assert(not service.IsInitialized, `the quest service is already initialized`)
			return service
		end,
	},
	{
		Name = "Profile",
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Profile")
			assert(not service.IsInitialized, `the profile service is already initialized`)
			return service
		end,
	},
	{
		Name = "Leaderstats",
		IsFeatured = FEATURES.Leaderstats,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Leaderstats")
			assert(not service.IsInitialized, `the leaderstats service is already initialized`)
			return service
		end,
	},
	{
		Name = "DayNight",
		IsFeatured = FEATURES.DayNight,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/DayNight")
			assert(not service.IsInitialized, `the day night service is already initialized`)
			return service
		end,
	},
	{
		Name = "Beacon",
		IsFeatured = FEATURES.Fixtures,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Beacon")
			assert(not service.IsInitialized, `the beacon service is already initialized`)
			return service
		end,
	},
	{
		Name = "Colorizer",
		IsFeatured = FEATURES.Fixtures,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Colorizer")
			assert(not service.IsInitialized, `the colorizer service is already initialized`)
			return service
		end,
	},
	{
		Name = "Rebuild",
		IsFeatured = FEATURES.Fixtures,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Rebuild")
			assert(not service.IsInitialized, `the rebuild service is already initialized`)
			return service
		end,
	},
	{
		Name = "Gate",
		IsFeatured = FEATURES.Fixtures,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Gate")
			assert(not service.IsInitialized, `the gate service is already initialized`)
			return service
		end,
	},
	{
		Name = "Hazard",
		IsFeatured = FEATURES.Fixtures,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Hazard")
			assert(not service.IsInitialized, `the hazard service is already initialized`)
			return service
		end,
	},
	{
		Name = "Reactor",
		IsFeatured = FEATURES.Fixtures,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Reactor")
			assert(not service.IsInitialized, `the reactor service is already initialized`)
			return service
		end,
	},
	{
		Name = "Uniform",
		IsFeatured = FEATURES.Uniforms,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Uniform")
			assert(not service.IsInitialized, `the uniform service is already initialized`)
			return service
		end,
	},
	-- these two put the server up for others to join, so they start once all of it is there + stop before any of it does
	{
		Name = "ServerId",
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/ServerId")
			assert(not service.IsInitialized, `the server id service is already initialized`)
			return service
		end,
	},
}
TableUtil.deepFreeze(ENTRIES)
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

do
	local names: { [string]: true } = {}
	for _, entry in ENTRIES do
		assert(ServiceType.Entry(entry))
		-- all of them are in before the first starts, so the second of a pair would go by without a word
		assert(not names[entry.Name], `the "{entry.Name}" service is listed twice`)
		names[entry.Name] = true
	end
end

-- the ones the game this place is built for runs, in the order they start in
Module.list = function(): { Entry }
	local entries: { Entry } = {}
	for _, entry in ENTRIES do
		if entry.IsFeatured ~= false then
			table.insert(entries, entry)
		end
	end
	return entries
end

return Module
