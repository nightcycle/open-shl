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
-- the ones that did + are known about: all three are disabled leftovers of the models they sit in. another is only
-- added here once it's been read
local ALLOWED_SCRIPT_PATHS = {
	"ReplicatedStorage/lib/base/decorations/rocket-car/Wheel",
	"ReplicatedStorage/lib/base/decorations/sports-car/Script",
	"ReplicatedStorage/lib/scene/hero-character-editor/Lighting/SpotLight/Script",
}
-- what wally installs isn't written here, so it isn't held to the rules below (ui-labs runs its stories with getfenv)
local PACKAGE_MOUNT_PATHS = { "ReplicatedStorage/Packages", "ReplicatedStorage/DevPackages" }
-- none of the code has a reason to load a module by its asset id, run a string or reach into an environment
local SOURCE_RULES: { SourceRule } = {
	{ name = "an asset require", pattern = "require%s*%(%s*%d" },
	{ name = "getfenv", pattern = "%f[%w_]getfenv%f[^%w_]" },
	{ name = "loadstring", pattern = "%f[%w_]loadstring%f[^%w_]" },
}
-- where a place says which game it is + which tags of its map the server runs, each with the class that wears it
local BUILD_CONFIG_PATH = "ReplicatedStorage/Generated/BUILD_CONFIG"
local GAME_PATTERN = '%f[%w_]GAME%s*=%s*"([^"]*)"'
local MAP_DEFINITION_PATH = "ServerScriptService/Server/Definition/Map"
local TAG_PATTERN = 'newTag%(%s*"([^"]+)"%s*,%s*"([^"]+)"%s*%)'
-- the tags the map of a game can't go without. one that lost them all still builds + boots, whatever they ran is just
-- not there. a game that isn't built yet has none
local NEEDED_TAGS: { [game.GameId]: { string } } = {
	shl1 = {},
	shl2 = { "StreetLamp", "NightWindows", "Uniform", "Hazard", "Beacon", "Gate", "Reactor", "Colorizer", "Rebuilt" },
	shl3 = { "Beacon" },
}
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

local function getScriptFailures(place: roblox.DataModel): { string }
	local failures: { string } = {}
	for _, desc in place:GetDescendants() do
		if not desc:IsA("LuaSourceContainer") then
			continue
		end
		local fullName = getFullName(place, desc)
		if not getIfInside(fullName, SCRIPT_MOUNT_PATHS) and table.find(ALLOWED_SCRIPT_PATHS, fullName) == nil then
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
	local gameId = (getSource(place, BUILD_CONFIG_PATH) or ""):match(GAME_PATTERN)
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
	for name, className in (getSource(place, MAP_DEFINITION_PATH) or ""):gmatch(TAG_PATTERN) do
		classNames[name] = className
	end
	if next(classNames) == nil then
		return { `"{MAP_DEFINITION_PATH}" doesn't say which tags the server runs` }
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
			table.insert(failures, `{gameId} needs the tag "{tag}", which "{MAP_DEFINITION_PATH}" doesn't have`)
		elseif not isWorn[tag] then
			table.insert(failures, `{gameId} needs the tag "{tag}", which nothing in the workspace wears`)
		end
	end
	return failures
end
-- Class
do
	local placePath = parseArgs(process.args)
	assert(fs.isFile(placePath), `No place file found at "{placePath}"`)
	local place = roblox.deserializePlace(fs.readFile(placePath))

	local count = 0
	local checks = { getCSGFailures(place), getScriptFailures(place), getMapFailures(place), getTagFailures(place) }
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
