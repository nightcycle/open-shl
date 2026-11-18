--!strict
-- in my experience, it is better to generate the project.json dynamically
-- this way you can swap out maps, remove unnecessary bloat / features, etc
-- better to just write your stuff that way from the start
-- I prefer to use lune rather than shell as this kind of thing benefits from flexibility
-- Services
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
-- Packages
-- Modules
local game = require("../modules/game")
local rojo = require("../modules/rojo")
-- Types
-- Constants
local PROJECT_PATH = process.env["PROJECT"] or "default.project.json"
local PROJECT_NAME = process.env["PROJECT_NAME"] or "superhero-life"
local MAP = process.env["MAP"] or "roblox-city"
-- the code is the same in every game, where its data, its items + its scenes come from isn't
local GAME: game.GameId = game.getId(process.env["GAME"])
local CONTENT = game.getContent(GAME)
-- what a story, a storybook + a spec are named, wherever in the code they sit. what wally installs is left as it came
local STORY_GLOBS = { "src/**/*.story.luau", "src/**/*.storybook.luau" }
local SPEC_GLOBS = { "src/**/*.spec.luau" }
-- Variables
-- References
-- Private Functions
-- a .env file leaves a variable unset by giving it no value, so an empty string counts as unset
local function getFlag(name: string, default: boolean): boolean
	local value = process.env[name]
	if value == nil or value == "" then
		return default
	end
	assert(value == "true" or value == "false", `{name} must be "true" or "false", received "{value}"`)
	return value == "true"
end
-- Class
do -- write in a do block now to make it easier to copy to other things later / turn into function / keep header more separate
	local project: rojo.ProjectJSON = {
		name = PROJECT_NAME :: string,
		tree = {
			["$className"] = "DataModel",
		},
	}
	local function appendService(serviceName: string, fn: (rojo.ProjectNode) -> ()?)
		local service: rojo.ProjectNode = {
			["$className"] = serviceName,
		}
		if fn then
			fn(service)
		end
		-- what a game sets on a service has the say over what all of them set on it
		local gameProperties = CONTENT.Properties[serviceName]
		if gameProperties then
			local properties: rojo.NodeProperties = service["$properties"] or {}
			for key, value in gameProperties do
				properties[key] = value
			end
			service["$properties"] = properties
		end
		assert(project.tree[serviceName] == nil, `duplicate service`)
		project.tree[serviceName] = service
	end
	appendService("ServerScriptService", function(node: rojo.ProjectNode)
		node["Server"] = {
			["$path"] = "src/server",
		}
		-- legacy save data stays server-side, each json file becomes a module
		node["Data"] = {
			["$path"] = CONTENT.DataPath,
		}
	end)

	appendService("ReplicatedStorage", function(node: rojo.ProjectNode)
		node["Shared"] = {
			["$path"] = "src/shared",
		}
		node["Generated"] = {
			["$path"] = "Generated",
		}
		node["Packages"] = {
			["$path"] = "Packages",
		}
		node["DevPackages"] = {
			["$path"] = "DevPackages",
		}
		node["lib"] = {
			["$className"] = "Folder",
			["base"] = {
				["$path"] = "lib/base",
			} :: rojo.ProjectNode,
			["character"] = game.newCharacterNode(CONTENT),
			-- props are worn like character items, but are not part of the item library
			["prop"] = {
				["$path"] = "lib/prop",
			} :: rojo.ProjectNode,
			["scene"] = {
				["$path"] = CONTENT.ScenePath,
			} :: rojo.ProjectNode,
		}
	end)

	appendService("StarterPlayer", function(node: rojo.ProjectNode)
		-- every avatar is dressed by the game, the look a player joins with would only load in late + cover it
		node["$properties"] = {
			LoadCharacterAppearance = false,
		} :: rojo.NodeProperties
		node["StarterPlayerScripts"] = {
			["$className"] = "StarterPlayerScripts",
			["Client"] = {
				["$path"] = "src/client",
			} :: rojo.ProjectNode,
		}
	end)

	appendService("Workspace", function(node: rojo.ProjectNode)
		-- a client is only sent what's around its avatar, closest first. what it can't do without wherever it stands
		-- is marked as persistent in the map
		node["$properties"] = {
			StreamingEnabled = true,
			-- an avatar that outruns the map is held where it is, not dropped through a floor that's on its way
			StreamingIntegrityMode = "PauseOutsideLoadedArea",
			-- what did get there stays for as long as the device has the memory, the skyline is part of the game
			StreamOutBehavior = "LowMemory",
		} :: rojo.NodeProperties
		node["Map"] = {
			["$path"] = `lib/map/{MAP}`,
		}
		-- nothing is sculpted, it's only there to hold the clouds of the map
		node["Terrain"] = {
			["$path"] = `lib/terrain/{MAP}`,
		}
	end)

	-- a place file that doesn't say which chat it runs falls back to the one the engine dropped, and the commands of a
	-- custom server only exist in the current one
	appendService("TextChatService", function(node: rojo.ProjectNode)
		node["$properties"] = {
			ChatVersion = "TextChatService",
		} :: rojo.NodeProperties
	end)

	-- a service none of the above has a word on is only there for the game that does
	for serviceName in CONTENT.Properties do
		if project.tree[serviceName] == nil then
			appendService(serviceName)
		end
	end

	-- the sky + the look of the light are tuned for a map, so they're swapped out along with it
	project.tree["Lighting"] = {
		["$path"] = `lib/lighting/{MAP}`,
	}

	-- ui labs reads the stories + a server that's told to runs the specs, neither is there for a player. a build has
	-- both unless it says otherwise, which the pipeline does for what it publishes. a server that runs its specs
	-- keeps them either way
	if not getFlag("STORIES_ENABLED", true) then
		local globs = table.clone(STORY_GLOBS)
		if not getFlag("TESTS_ENABLED", false) then
			table.move(SPEC_GLOBS, 1, #SPEC_GLOBS, #globs + 1, globs)
		end
		project.globIgnorePaths = globs
	end

	fs.writeFile(PROJECT_PATH, serde.encode("json", project, true))
end
