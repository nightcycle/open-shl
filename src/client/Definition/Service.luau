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
-- in dependency order. one that isn't this game's is never required, so whatever it waits on doesn't have to be in the
-- place
local ENTRIES: { Entry } = {
	{
		Name = "Network",
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
			assert(not service.IsInitialized, `the network service is already initialized`)
			return service
		end,
	},
	{
		Name = "VFX",
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/VFX")
			assert(not service.IsInitialized, `the vfx service is already initialized`)
			return service
		end,
	},
	{
		Name = "Ability",
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Ability")
			assert(not service.IsInitialized, `the ability service is already initialized`)
			return service
		end,
	},
	{
		Name = "Prop",
		IsFeatured = FEATURES.Props,
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Prop")
			assert(not service.IsInitialized, `the prop service is already initialized`)
			return service
		end,
	},
	{
		Name = "Session",
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
			assert(not service.IsInitialized, `the session service is already initialized`)
			return service
		end,
	},
	{
		Name = "Shell",
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
			assert(not service.IsInitialized, `the shell service is already initialized`)
			return service
		end,
	},
	{
		Name = "Music",
		IsFeatured = FEATURES.Music,
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Music")
			assert(not service.IsInitialized, `the music service is already initialized`)
			return service
		end,
	},
	{
		Name = "CameraMode",
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/CameraMode")
			assert(not service.IsInitialized, `the camera mode service is already initialized`)
			return service
		end,
	},
	{
		Name = "Swap",
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Swap")
			assert(not service.IsInitialized, `the swap service is already initialized`)
			return service
		end,
	},
	-- the emotes of the actions menu + the arms of whoever is cuffed: a game without either has nobody to pose, one
	-- that holds its villains has their arms to
	{
		Name = "Emote",
		IsFeatured = FEATURES.Roleplay or FEATURES.Teams,
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Emote")
			assert(not service.IsInitialized, `the emote service is already initialized`)
			return service
		end,
	},
	{
		Name = "Residence",
		IsFeatured = FEATURES.Residences,
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Residence")
			assert(not service.IsInitialized, `the residence service is already initialized`)
			return service
		end,
	},
	{
		Name = "Build",
		IsFeatured = FEATURES.Furniture,
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Build")
			assert(not service.IsInitialized, `the build service is already initialized`)
			return service
		end,
	},
	{
		Name = "QuestGiver",
		IsFeatured = FEATURES.Quests,
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/QuestGiver")
			assert(not service.IsInitialized, `the quest giver service is already initialized`)
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
