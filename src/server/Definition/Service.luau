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
	-- a server of a game whose private ones have a toggle is told what it plays by in here, before anything asks
	{
		Name = "VipServer",
		IsFeatured = FEATURES.PrivateServerToggle,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/VipServer")
			assert(not service.IsInitialized, `the vip server service is already initialized`)
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
	-- what a player does to their own avatar, where the game has them at it, + the cuffs the server puts on somebody:
	-- a game that holds its villains runs it for those alone
	{
		Name = "Roleplay",
		IsFeatured = FEATURES.Roleplay or FEATURES.Teams,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Roleplay")
			assert(not service.IsInitialized, `the roleplay service is already initialized`)
			return service
		end,
	},
	-- a hero's mask off + on, for a game that has that with or without the rest of roleplay
	{
		Name = "Mask",
		IsFeatured = FEATURES.Mask,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Mask")
			assert(not service.IsInitialized, `the mask service is already initialized`)
			return service
		end,
	},
	-- what an avatar holds that isn't a power, + the pads of the map that hand it out
	{
		Name = "Prop",
		IsFeatured = FEATURES.Props,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Prop")
			assert(not service.IsInitialized, `the prop service is already initialized`)
			return service
		end,
	},
	{
		Name = "Pickup",
		IsFeatured = FEATURES.Props,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Pickup")
			assert(not service.IsInitialized, `the pickup service is already initialized`)
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
	-- the words that pay out once for whoever types one. it writes into the save of a session
	{
		Name = "Code",
		IsFeatured = FEATURES.Codes,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Code")
			assert(not service.IsInitialized, `the code service is already initialized`)
			return service
		end,
	},
	-- what everybody is handed for being in a server. it pays through the economy
	{
		Name = "Allowance",
		IsFeatured = FEATURES.Allowance,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Allowance")
			assert(not service.IsInitialized, `the allowance service is already initialized`)
			return service
		end,
	},
	-- what being in the group of the game gives. it writes into the save of a session
	{
		Name = "Promo",
		IsFeatured = FEATURES.Promo,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Promo")
			assert(not service.IsInitialized, `the promo service is already initialized`)
			return service
		end,
	},
	-- what's behind a pass for a fee. it stores a character the way the character service has one stored
	{
		Name = "Rent",
		IsFeatured = FEATURES.Rent,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Rent")
			assert(not service.IsInitialized, `the rent service is already initialized`)
			return service
		end,
	},
	-- who's on which side, where players take one, + the jail the avatars of one of them come in at. downing somebody
	-- pays, so the sides start once there's something to pay with
	{
		Name = "Team",
		IsFeatured = FEATURES.Teams,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Team")
			assert(not service.IsInitialized, `the team service is already initialized`)
			return service
		end,
	},
	-- the line the town puts on the screens of its heroes, or of whoever a service has a word for
	{
		Name = "Alert",
		IsFeatured = FEATURES.Teams,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Alert")
			assert(not service.IsInitialized, `the alert service is already initialized`)
			return service
		end,
	},
	{
		Name = "Jail",
		IsFeatured = FEATURES.Teams,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Jail")
			assert(not service.IsInitialized, `the jail service is already initialized`)
			return service
		end,
	},
	-- the bodies nobody plays. it puts none into the world by itself, so it's up before whatever asks it for a wave
	{
		Name = "Npc",
		IsFeatured = FEATURES.Npcs,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Npc")
			assert(not service.IsInitialized, `the npc service is already initialized`)
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
	-- the day of a game with weather + seasons: it keeps the time + rolls the sky, every client draws them for itself
	{
		Name = "Environment",
		IsFeatured = FEATURES.Environment,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Environment")
			assert(not service.IsInitialized, `the environment service is already initialized`)
			return service
		end,
	},
	-- what the villains of a town do to it for money + what follows: it asks the sides, pays through the economy, tells
	-- the heroes through the alerts + reads the clock of the day
	{
		Name = "Crime",
		IsFeatured = FEATURES.Crime,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Crime")
			assert(not service.IsInitialized, `the crime service is already initialized`)
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
	-- a grid of beams that's lethal while it's lit: the town's guard against its villains, the hazards do the killing
	{
		Name = "LaserGate",
		IsFeatured = FEATURES.Crime,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/LaserGate")
			assert(not service.IsInitialized, `the laser gate service is already initialized`)
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
	-- the pads of the map that set whoever steps on one down somewhere else
	{
		Name = "Telepad",
		IsFeatured = FEATURES.Telepads,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Telepad")
			assert(not service.IsInitialized, `the telepad service is already initialized`)
			return service
		end,
	},
	-- what a map has to play with that everybody sees the same: a door that's clicked open, a screen, a seat
	{
		Name = "Scenery",
		IsFeatured = FEATURES.Scenery,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Scenery")
			assert(not service.IsInitialized, `the scenery service is already initialized`)
			return service
		end,
	},
	-- puts the server up for others to join by its id, so it starts once all of it is there + stops before any of it
	-- does. a game without a list of servers has no box to enter an id in, there it wrote a record nobody looked up
	{
		Name = "ServerId",
		IsFeatured = FEATURES.CustomServers,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/ServerId")
			assert(not service.IsInitialized, `the server id service is already initialized`)
			return service
		end,
	},
	-- what an agent drives the game through, in a place that was built for it: it requires the services it drives, so
	-- it starts once they're all up. no other place has the module, let alone requires it
	{
		Name = "Harness",
		-- a config that was generated before there was such a switch has no word on it, which is a no
		IsFeatured = BUILD_CONFIG.HARNESS_ENABLED == true,
		Load = function(): Service
			local service = require("@game/ServerScriptService/Server/Service/Harness")
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
