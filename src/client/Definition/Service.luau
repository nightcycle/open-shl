--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
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
	-- who speaks is named by who they play. the engine asks one thing per client about a line, this is who answers
	{
		Name = "Chat",
		IsFeatured = FEATURES.Chat,
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Chat")
			assert(not service.IsInitialized, `the chat service is already initialized`)
			return service
		end,
	},
	-- the sky, the season + the hour of a game with weather: its server says them, this client draws them for itself
	{
		Name = "Environment",
		IsFeatured = FEATURES.Environment,
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Environment")
			assert(not service.IsInitialized, `the environment service is already initialized`)
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
	-- the parts of a map that only turn, each client turns the ones it has
	{
		Name = "Scenery",
		IsFeatured = FEATURES.Scenery,
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Scenery")
			assert(not service.IsInitialized, `the scenery service is already initialized`)
			return service
		end,
	},
	-- what's seen of the crimes of a town that its server doesn't put in the world itself: the bar over a target
	{
		Name = "Crime",
		IsFeatured = FEATURES.Crime,
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Crime")
			assert(not service.IsInitialized, `the crime service is already initialized`)
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
	-- the free camera, where the hud of a game has the button for it
	{
		Name = "CameraMode",
		IsFeatured = FEATURES.CameraMode,
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
	-- the flips + rolls a player throws their own avatar into: nothing of them is the server's to hear of
	{
		Name = "Acrobatics",
		IsFeatured = FEATURES.Acrobatics,
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Acrobatics")
			assert(not service.IsInitialized, `the acrobatics service is already initialized`)
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
	-- what an agent drives this client through, in a place that was built for it: it requires the services it drives,
	-- so it starts once they're all up. no other place has the module, let alone requires it
	{
		Name = "Harness",
		-- a config that was generated before there was such a switch has no word on it, which is a no
		IsFeatured = BUILD_CONFIG.HARNESS_ENABLED == true,
		Load = function(): Service
			local service = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Harness")
			assert(not service.IsInitialized, `the harness service is already initialized`)
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
