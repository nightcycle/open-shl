--!strict
-- every place is the same code built for one game. the code picks its own rows from the id that's baked into the
-- build config, what a game is made of besides code is written down here: where its data, its items + its scenes come
-- from and what its services are set to
-- Services
local fs = require("@lune/fs")
-- Packages
-- Modules
local rojo = require("./rojo")
-- Types
export type GameId = "shl1" | "shl2" | "shl3"
export type GameContent = {
	-- becomes ServerScriptService/Data
	DataPath: string,
	-- becomes ReplicatedStorage/lib/scene, with the folder names the shared components wait on
	ScenePath: string,
	-- the items of the game, as <group>/<category>/<key>
	CharacterPath: string,
	-- the items it wears out of the library of SHL2, one <group>/<category>/<key> per line. a game without a list
	-- borrows nothing + its own library is mounted as it is
	BorrowListPath: string?,
	-- laid over what every game sets on a service, by the name of the service
	Properties: { [string]: { [string]: rojo.PropertyValue } },
}
-- Constants
-- a build that isn't told is the game this code was written for, so nothing that builds today has to say it
local DEFAULT_ID: GameId = "shl2"
local IDS: { GameId } = { "shl1", "shl2", "shl3" }
-- SHL2's items are the ones the other games borrow from
local BORROW_PATH = "lib/character/shl-2"
local BORROW_DELIMITER = "/"
local BORROW_COMMENT = "#"
-- an item is a folder of its parts or a single model file, either way it's named by its key
local MODEL_EXTENSIONS = { ".model.json", ".rbxm", ".rbxmx" }
local CONTENTS: { [GameId]: GameContent } = table.freeze({
	shl1 = table.freeze({
		DataPath = "data/shl1",
		ScenePath = "lib/scene/shl-1",
		CharacterPath = "lib/character/shl-1",
		BorrowListPath = "lib/character/shl-1/borrow.txt",
		-- what the legacy place was set to
		Properties = {
			MaterialService = { Use2022Materials = false },
			Players = { RespawnTime = 5 },
			StarterPlayer = { CameraMaxZoomDistance = 400 },
		},
	}),
	shl2 = table.freeze({
		DataPath = "data/shl2",
		ScenePath = "lib/scene/shl-2",
		CharacterPath = BORROW_PATH,
		-- it's the game every shared setting was tuned for
		Properties = {},
	}),
	shl3 = table.freeze({
		DataPath = "data/shl3",
		ScenePath = "lib/scene/shl-3",
		CharacterPath = "lib/character/shl-3",
		BorrowListPath = "lib/character/shl-3/borrow.txt",
		-- what the legacy place was set to
		Properties = {
			MaterialService = { Use2022Materials = false },
			Players = { RespawnTime = 5 },
			-- the place said 16, a script of every avatar set 18 the moment it spawned
			StarterPlayer = { CameraMaxZoomDistance = 40, CharacterWalkSpeed = 18 },
		},
	}),
})
-- Variables
-- References
-- Private Functions
local function getDirNames(path: string): { string }
	local names: { string } = {}
	for _, name in fs.readDir(path) do
		if fs.isDir(`{path}/{name}`) then
			table.insert(names, name)
		end
	end
	return names
end

local function getItemPath(categoryPath: string, key: string): string?
	local path = `{categoryPath}/{key}`
	if fs.isDir(path) then
		return path
	end
	for _, extension in MODEL_EXTENSIONS do
		if fs.isFile(path .. extension) then
			return path .. extension
		end
	end
	return nil
end

local function readBorrowList(path: string): { string }
	local lines: { string } = {}
	for _, line in string.split(fs.readFile(path), "\n") do
		line = string.gsub(line, "%s+$", "")
		if line ~= "" and string.sub(line, 1, #BORROW_COMMENT) ~= BORROW_COMMENT then
			table.insert(lines, line)
		end
	end
	return lines
end
-- Class
local Module = {}

Module.DEFAULT_ID = DEFAULT_ID
Module.IDS = IDS
-- the library of SHL2, which every line of a borrow list names an item of
Module.BORROW_PATH = BORROW_PATH
-- as it's written down, whether any of it is there yet: a tool that writes the content of a game asks where it goes
Module.CONTENTS = CONTENTS

-- the game a build variable asks for. a .env file leaves a variable unset by giving it no value, so an empty string
-- counts as unset
Module.getId = function(value: string?): GameId
	if value == nil or value == "" then
		return DEFAULT_ID
	end
	for _, id: GameId in IDS do
		if id == value then
			return id
		end
	end
	error(`GAME must be one of {table.concat(IDS, ", ")}, received "{value}"`)
end

-- what a game is built from. one whose content isn't in the repo yet says so here, rojo would only name a path
Module.getContent = function(id: GameId): GameContent
	local content = CONTENTS[id]
	for _, path in { content.DataPath, content.ScenePath, content.CharacterPath } do
		assert(fs.isDir(path), `GAME={id} is built from "{path}", which isn't there`)
	end
	return content
end

-- ReplicatedStorage/lib/character of a game. a game that borrows nothing gets its library as it is. for one that does
-- every category is its own folder of that name, if it has one, plus a child per item it borrows
Module.newCharacterNode = function(content: GameContent): rojo.ProjectNode
	local ownPath = content.CharacterPath
	local borrowListPath = content.BorrowListPath
	if borrowListPath == nil then
		return {
			["$path"] = ownPath,
		}
	end

	local node: rojo.ProjectNode = {
		["$className"] = "Folder",
	}
	local function getCategoryNode(group: string, category: string): rojo.ProjectNode
		local groupNode: rojo.ProjectNode = node[group] or {
			["$className"] = "Folder",
		}
		node[group] = groupNode
		local categoryPath = `{ownPath}/{group}/{category}`
		local categoryNode: rojo.ProjectNode = groupNode[category]
			or if fs.isDir(categoryPath) then { ["$path"] = categoryPath } else { ["$className"] = "Folder" }
		groupNode[category] = categoryNode
		return categoryNode
	end
	for _, group in getDirNames(ownPath) do
		for _, category in getDirNames(`{ownPath}/{group}`) do
			getCategoryNode(group, category)
		end
	end

	-- a game can go without a list for as long as all it wears is its own
	if fs.isFile(borrowListPath) then
		for _, line in readBorrowList(borrowListPath) do
			local keys = string.split(line, BORROW_DELIMITER)
			assert(#keys == 3, `"{line}" of "{borrowListPath}" isn't a <group>/<category>/<key>`)
			local group, category, key = keys[1], keys[2], keys[3]
			local itemPath = getItemPath(`{BORROW_PATH}/{group}/{category}`, key)
			assert(
				itemPath,
				`"{line}" of "{borrowListPath}" isn't in "{BORROW_PATH}", the library of SHL2 it borrows from`
			)
			-- rojo builds a child of the project + a child on disk of the same name as two instances
			assert(
				getItemPath(`{ownPath}/{group}/{category}`, key) == nil,
				`"{line}" is borrowed by "{borrowListPath}" + in "{ownPath}"`
			)
			local categoryNode = getCategoryNode(group, category)
			assert(categoryNode[key] == nil, `"{line}" is in "{borrowListPath}" twice`)
			categoryNode[key] = {
				["$path"] = itemPath,
			}
		end
	end
	return node
end

return Module
