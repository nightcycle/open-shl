--!strict
-- reads a built place for what should never ship in one + for what its map has to hold. whether it boots is checked
-- by hand in studio, this only goes by what's in the file
-- Services
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
-- Packages
-- Modules
local game = require("../modules/game")
-- Types
type SourceRule = { name: string, pattern: string }
-- Constants
local USAGE = "Usage: lune run scripts/ci/check-place.lune.luau <place.rbxl>"
local PATH_DELIMITER = "/"
-- nothing of the project goes there + studio doesn't list them, which is how a backdoor rides along in a place file
local CSG_SERVICE_CLASS_NAMES = { "CSGDictionaryService", "NonReplicatedCSGDictionaryService" }
-- where scripts/proj/config.lune.luau puts code, a script anywhere else came in with a model
local SCRIPT_MOUNT_PATHS = {
	"ServerScriptService/Server",
	"ServerScriptService/Data",
	"ReplicatedStorage/Shared",
	"ReplicatedStorage/Generated",
	"ReplicatedStorage/Packages",
	"ReplicatedStorage/DevPackages",
	"StarterPlayer/StarterPlayerScripts/Client",
}
-- the ones that did + are known about: all three are disabled leftovers of the models they sit in, in libraries only
-- shl2 mounts. another is only added here once it's been read, for the game whose place it's in: a place of a game
-- that has none listed is held to having none
local ALLOWED_SCRIPT_PATHS: { [game.GameId]: { string } } = {
	shl1 = {},
	shl2 = {
		"ReplicatedStorage/lib/base/decorations/rocket-car/Wheel",
		"ReplicatedStorage/lib/base/decorations/sports-car/Script",
		"ReplicatedStorage/lib/scene/hero-character-editor/Lighting/SpotLight/Script",
	},
	shl3 = {},
}
-- what wally installs isn't written here, so it isn't held to the rules below (ui-labs runs its stories with getfenv)
local PACKAGE_MOUNT_PATHS = { "ReplicatedStorage/Packages", "ReplicatedStorage/DevPackages" }
-- none of the code has a reason to load a module by its asset id, run a string or reach into an environment
local SOURCE_RULES: { SourceRule } = {
	{ name = "an asset require", pattern = "require%s*%(%s*%d" },
	{ name = "getfenv", pattern = "%f[%w_]getfenv%f[^%w_]" },
	{ name = "loadstring", pattern = "%f[%w_]loadstring%f[^%w_]" },
}
-- where a place says which game it is + which tags of its map the game runs, each with the class that wears it. the
-- ones both sides read are declared apart from the ones only the server runs
local BUILD_CONFIG_PATH = "ReplicatedStorage/Generated/BUILD_CONFIG"
local GAME_PATTERN = '%f[%w_]GAME%s*=%s*"([^"]*)"'
local MAP_DEFINITION_PATHS = { "ReplicatedStorage/Shared/Definition/Map", "ServerScriptService/Server/Definition/Map" }
local TAG_PATTERN = 'newTag%(%s*"([^"]+)"%s*,%s*"([^"]+)"%s*%)'
-- the tags the map of a game can't go without. one that lost them all still builds + boots, whatever they ran is just
-- not there
local NEEDED_TAGS: { [game.GameId]: { string } } = {
	shl1 = {
		"Spawn",
		"PlayArea",
		"NightWindows",
		"Telepad",
		"TelepadExit",
		"ClickDoor",
		"ImageCycle",
		"FaceSwap",
		"Spin",
	},
	shl2 = { "StreetLamp", "NightWindows", "Uniform", "Hazard", "Beacon", "Gate", "Reactor", "Colorizer", "Rebuilt" },
	shl3 = {
		"Beacon",
		"Spawn",
		"PlayArea",
		"Water",
		"IntroCamera",
		"PropPad",
		"JailCell",
		"JailCenter",
		"Road",
		"HeroGate",
		"Troublesome",
		"NightWindows",
		"SeasonGround",
		"SeasonWater",
		"Foliage",
		"Fountain",
		"Spout",
		"Bank",
		"LaserBeam",
		"VaultDoor",
		"LaserGate",
		"DisasterTarget",
		"ZombieSpawn",
		"ApartmentAnchor",
		"ApartmentEntrance",
		"ApartmentSalesman",
		"JobPad",
		"Telepad",
		"TelepadExit",
	},
}
-- the libraries only some of the games are built with, by the game that is. a place holds the ones of its game +
-- none of another's: what waits on one that's missing never starts, + nothing says so
local GAME_LIBRARY_PATHS: { [game.GameId]: { string } } = {
	shl1 = {},
	shl2 = {},
	shl3 = {
		"ReplicatedStorage/lib/apartment",
		"ServerStorage/lib/npc",
		-- the skies, the grades + what falls: a weather that names one that's gone only warns on a client
		"Lighting/Skyboxes",
		"Lighting/Atmospheres",
		"Lighting/Precipitation",
	},
}
-- where a game lists the halves of its abilities, each side in a module that goes by the name of the game. the two
-- lists are kept by hand + neither side can see the other's, so only a read of both tells that they agree
local ABILITY_SET_PATHS = {
	server = "ServerScriptService/Server/Ability/Set",
	client = "StarterPlayer/StarterPlayerScripts/Client/Ability/Set",
}
local ABILITY_HALF_PATTERN = 'Ability/Library/([%w_/]+)"'
-- what both halves of an ability share, it names the power the ability is built for
local ABILITY_LAYOUT_PATH = "ReplicatedStorage/Shared/Ability/Library"
local POWER_ID_PATTERN = '"([%l%-]+_[%l%d%-]+)"'
-- the powers of a game, in a module that goes by its name. the rows below the mark aren't offered yet
local POWER_CATALOGUE_PATH = "ReplicatedStorage/Shared/Definition/Power"
local POWER_ROW_PATTERN = 'Id%s*=%s*"([^"]+)"'
local POWER_UPCOMING_MARK = "local UPCOMING"
-- Variables
-- References
-- Private Functions
local function parseArgs(args: { string }): string
	assert(#args == 1, `Expected a place\n{USAGE}`)
	return (args[1]:gsub("\\", "/"))
end

local function getFullName(root: roblox.Instance, inst: roblox.Instance): string
	local names: { string } = {}
	local current: roblox.Instance? = inst
	while current and current ~= root do
		table.insert(names, 1, current.Name)
		current = current.Parent
	end
	return table.concat(names, PATH_DELIMITER)
end

local function getIfInside(fullName: string, paths: { string }): boolean
	for _, path in paths do
		if fullName == path or fullName:sub(1, #path + 1) == path .. PATH_DELIMITER then
			return true
		end
	end
	return false
end

local function getSource(place: roblox.DataModel, path: string): string?
	local current: roblox.Instance = place
	for _, name in path:split(PATH_DELIMITER) do
		local child = current:FindFirstChild(name)
		if child == nil then
			return nil
		end
		current = child
	end
	if not current:IsA("LuaSourceContainer") then
		return nil
	end
	return (current :: any).Source
end

-- a service can be renamed, its class can't
local function getCSGFailures(place: roblox.DataModel): { string }
	local failures: { string } = {}
	for _, service in place:GetChildren() do
		if table.find(CSG_SERVICE_CLASS_NAMES, service.ClassName) == nil then
			continue
		end
		for _, desc in service:GetDescendants() do
			table.insert(failures, `{service.ClassName} holds {desc.ClassName} "{getFullName(place, desc)}"`)
		end
	end
	return failures
end

local function getGameId(place: roblox.DataModel): string?
	return (getSource(place, BUILD_CONFIG_PATH) or ""):match(GAME_PATTERN)
end

local function getScriptFailures(place: roblox.DataModel): { string }
	local failures: { string } = {}
	-- a place that doesn't say which game it is has nothing let through
	local gameId = getGameId(place)
	local allowedPaths: { string } = {}
	for id, paths in ALLOWED_SCRIPT_PATHS do
		if id == gameId then
			allowedPaths = paths
		end
	end
	for _, desc in place:GetDescendants() do
		if not desc:IsA("LuaSourceContainer") then
			continue
		end
		local fullName = getFullName(place, desc)
		if not getIfInside(fullName, SCRIPT_MOUNT_PATHS) and table.find(allowedPaths, fullName) == nil then
			table.insert(failures, `{desc.ClassName} "{fullName}" is outside of every script mount`)
		end
		if getIfInside(fullName, PACKAGE_MOUNT_PATHS) then
			continue
		end
		local source: string = (desc :: any).Source
		for _, rule in SOURCE_RULES do
			if source:find(rule.pattern) then
				table.insert(failures, `{desc.ClassName} "{fullName}" has {rule.name} in its source`)
			end
		end
	end
	return failures
end

local function getMapFailures(place: roblox.DataModel): { string }
	local workspace = place:FindFirstChildOfClass("Workspace")
	if workspace == nil or workspace:FindFirstChild("Map") == nil then
		return { `there is no "Workspace{PATH_DELIMITER}Map"` }
	end
	return {}
end

-- the server finds what it runs in a map by its tags. one on the wrong class is skipped with a warning + one that's
-- on nothing at all is never missed, so neither shows up in a boot
local function getTagFailures(place: roblox.DataModel): { string }
	local gameId = getGameId(place)
	local neededTags: { string }? = nil
	for id, tags in NEEDED_TAGS do
		if id == gameId then
			neededTags = tags
		end
	end
	if gameId == nil or neededTags == nil then
		return { `"{BUILD_CONFIG_PATH}" doesn't say which game this is` }
	end
	local classNames: { [string]: string } = {}
	for _, path in MAP_DEFINITION_PATHS do
		local count = 0
		for name, className in (getSource(place, path) or ""):gmatch(TAG_PATTERN) do
			classNames[name] = className
			count += 1
		end
		if count == 0 then
			return { `"{path}" doesn't say which tags the game runs` }
		end
	end

	local failures: { string } = {}
	local isWorn: { [string]: true } = {}
	local workspace = place:FindFirstChildOfClass("Workspace")
	local descendants: { roblox.Instance } = if workspace then workspace:GetDescendants() else {}
	for _, desc in descendants do
		for _, tag in desc:GetTags() do
			local className = classNames[tag]
			if className == nil then
				continue
			end
			if desc:IsA(className) then
				isWorn[tag] = true
			else
				local fullName = getFullName(place, desc)
				table.insert(failures, `{desc.ClassName} "{fullName}" is tagged "{tag}" but isn't a {className}`)
			end
		end
	end
	for _, tag in neededTags do
		if classNames[tag] == nil then
			table.insert(failures, `{gameId} needs the tag "{tag}", which no map definition has`)
		elseif not isWorn[tag] then
			table.insert(failures, `{gameId} needs the tag "{tag}", which nothing in the workspace wears`)
		end
	end
	return failures
end

local function getLibraryFailures(place: roblox.DataModel): { string }
	local gameId = getGameId(place)
	local failures: { string } = {}
	local ownPaths: { string } = {}
	for id, paths in GAME_LIBRARY_PATHS do
		if id == gameId then
			ownPaths = paths
		end
	end
	for id, paths in GAME_LIBRARY_PATHS do
		for _, path in paths do
			local current: roblox.Instance? = place
			for _, name in path:split(PATH_DELIMITER) do
				current = if current then current:FindFirstChild(name) else nil
			end
			if id == gameId and current == nil then
				table.insert(failures, `{id} is built with the library "{path}", which isn't there`)
			elseif current ~= nil and table.find(ownPaths, path) == nil then
				table.insert(failures, `"{path}" is a library of {id}, this is a place of {gameId or "no game"}`)
			end
		end
	end
	return failures
end

-- an ability is two halves + a power to be handed out as. a half that only one side lists leaves the other with a
-- tool that does nothing, and a power nothing is built for is offered all the same: neither stops a boot
local function getAbilityFailures(place: roblox.DataModel): { string }
	local gameId = getGameId(place)
	if gameId == nil then
		return {}
	end
	local siblingName = gameId:upper()
	local serverSource = getSource(place, `{ABILITY_SET_PATHS.server}{PATH_DELIMITER}{siblingName}`)
	local clientSource = getSource(place, `{ABILITY_SET_PATHS.client}{PATH_DELIMITER}{siblingName}`)
	-- a game that isn't built yet has neither
	if serverSource == nil and clientSource == nil then
		return {}
	end
	local failures: { string } = {}
	local halves: { [string]: { [string]: true } } = { server = {}, client = {} }
	for side, source in { server = serverSource or "", client = clientSource or "" } do
		for half in source:gmatch(ABILITY_HALF_PATTERN) do
			halves[side][half] = true
		end
		if next(halves[side]) == nil then
			table.insert(failures, `{gameId} has no abilities in the set of its {side}`)
		end
	end
	local powerHalves: { [string]: string } = {}
	for side, others in { server = "client", client = "server" } do
		for half in halves[side] do
			if not halves[others][half] then
				table.insert(failures, `the {side} of {gameId} has the ability "{half}", its {others} doesn't`)
			end
			local layoutPath = `{ABILITY_LAYOUT_PATH}{PATH_DELIMITER}{half}`
			local powerId = (getSource(place, layoutPath) or ""):match(POWER_ID_PATTERN)
			if powerId == nil then
				table.insert(failures, `the ability "{half}" of {gameId} names no power in "{layoutPath}"`)
			else
				powerHalves[powerId] = half
			end
		end
	end
	local catalogue = getSource(place, `{POWER_CATALOGUE_PATH}{PATH_DELIMITER}{siblingName}`) or ""
	local offered = catalogue:sub(1, (catalogue:find(POWER_UPCOMING_MARK, 1, true) or #catalogue + 1) - 1)
	local isOffered: { [string]: true } = {}
	for powerId in offered:gmatch(POWER_ROW_PATTERN) do
		isOffered[powerId] = true
		if powerHalves[powerId] == nil then
			table.insert(failures, `{gameId} offers the power "{powerId}", no ability of its sets is built for it`)
		end
	end
	for powerId, half in powerHalves do
		if not isOffered[powerId] then
			table.insert(
				failures,
				`the ability "{half}" of {gameId} is built for "{powerId}", which {gameId} doesn't offer`
			)
		end
	end
	table.sort(failures)
	return failures
end
-- Class
do
	local placePath = parseArgs(process.args)
	assert(fs.isFile(placePath), `No place file found at "{placePath}"`)
	local place = roblox.deserializePlace(fs.readFile(placePath))

	local count = 0
	local checks = {
		getCSGFailures(place),
		getScriptFailures(place),
		getMapFailures(place),
		getTagFailures(place),
		getLibraryFailures(place),
		getAbilityFailures(place),
	}
	for _, failures in checks do
		for _, failure in failures do
			count += 1
			print(failure)
		end
	end
	if count > 0 then
		print(`{count} problem(s) in "{placePath}"`)
		process.exit(1)
	end
	print(`nothing wrong with "{placePath}"`)
end
