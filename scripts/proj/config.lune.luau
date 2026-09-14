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
			["$path"] = "src/server"
		}
	end)

	appendService("ReplicatedStorage", function(node: rojo.ProjectNode)
		node["Shared"] = {
			["$path"] = "src/shared"
		}
		node["Generated"] = {
			["$path"] = "Generated"
		}
		node["Packages"] = {
			["$path"] = "Packages"
		}
		node["DevPackages"] = {
			["$path"] = "DevPackages"
		}
	end)

	appendService("StarterPlayer", function(node: rojo.ProjectNode)
		node["StarterPlayerScripts"] = {
			["$className"] = "StarterPlayerScripts",
			["Client"] = {
				["$path"] = "src/client"
			} :: rojo.ProjectNode
		}
	end)

	appendService("Workspace", function(node: rojo.ProjectNode)
		node["Map"] = {
			["$path"] = `lib/map/{MAP}`
		}
	end)

	fs.writeFile(PROJECT_PATH, serde.encode("json", project, true))
end
