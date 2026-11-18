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
local rojo = require("../modules/rojo")
-- Types
-- Constants
local PROJECT_PATH = process.env["PROJECT"] or "default.project.json"
local PROJECT_NAME = process.env["PROJECT_NAME"] or "superhero-life"
local MAP = process.env["MAP"] or "roblox-city"
-- Variables
-- References
-- Private Functions
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
		assert(project.tree[serviceName] == nil, `duplicate service`)
		project.tree[serviceName] = service
	end
	appendService("ServerScriptService", function(node: rojo.ProjectNode)
		node["Server"] = {
			["$path"] = "src/server",
		}
		-- legacy save data stays server-side, each json file becomes a module
		node["Data"] = {
			["$path"] = "data",
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
			["character"] = {
				["$path"] = "lib/character",
			} :: rojo.ProjectNode,
			-- props are worn like character items, but are not part of the item library
			["prop"] = {
				["$path"] = "lib/prop",
			} :: rojo.ProjectNode,
			["scene"] = {
				["$path"] = "lib/scene",
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
		node["Map"] = {
			["$path"] = `lib/map/{MAP}`,
		}
		-- nothing is sculpted, it's only there to hold the clouds of the map
		node["Terrain"] = {
			["$path"] = `lib/terrain/{MAP}`,
		}
	end)

	-- the sky + the look of the light are tuned for a map, so they're swapped out along with it
	project.tree["Lighting"] = {
		["$path"] = `lib/lighting/{MAP}`,
	}

	fs.writeFile(PROJECT_PATH, serde.encode("json", project, true))
end
