--!strict
-- Services
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
-- Packages
-- Modules
local rojo = require("../modules/rojo")
-- Types
-- Constants
local PATH = process.args[1]
-- Variables
-- References
-- Private Functions
local function unpackInst(dir: string, name: string, inst: roblox.Instance, depth: number)
	if
		inst.ClassName == "Folder"
		or inst.ClassName == "Configuration"
		or (depth == 0 and inst.ClassName == "Model")
	then
		if not fs.isDir(dir .. "/" .. name) then
			fs.writeDir(dir .. "/" .. name)
		end
		local hasAttributes = false
		for _, _ in inst:GetAttributes() do
			hasAttributes = true
			break
		end
		if #inst:GetTags() > 0 or hasAttributes then
			local properties: rojo.NodeProperties = {}

			if hasAttributes then
				properties.Attributes = {
					Attributes = {},
				}
				assert(properties.Attributes, `bad attributes`)
				for k, v in inst:GetAttributes() do
					properties.Attributes.Attributes[k] = v
				end
			end
			if #inst:GetTags() > 0 then
				properties.Tags = {}
				assert(properties.Tags, `bad tags`)
				for i, v in inst:GetTags() do
					table.insert(properties.Tags, v)
				end
			end
			fs.writeFile(
				dir .. "/init.meta.json",
				serde.encode(
					"json",
					{
						className = inst.ClassName,
						properties = properties,
					} :: rojo.MetaJSON,
					true
				)
			)
		end
		local dupeIndex: { [string]: number } = {}
		for i, child in inst:GetChildren() do
			if not dupeIndex[child.Name] then
				dupeIndex[child.Name] = 0
			end
			local origName = child.Name
			if dupeIndex[child.Name] > 0 then
				child.Name = `{child.Name}_{dupeIndex[child.Name]}`
			end
			unpackInst(dir .. "/" .. name, child.Name, child, depth + 1)
			dupeIndex[origName] += 1
		end
	else
		local path = dir .. "/" .. name .. ".rbxm"
		if fs.isFile(path) then
		end
		fs.writeFile(path, roblox.serializeModel({ inst }))
	end
end
-- Class
local function parseFile(path: string, depth: number)
	print(`parsing "{path}"`)
	local rbxmArray = roblox.deserializeModel(fs.readFile(path))
	assert(#rbxmArray == 1, `multi-header models not supported`)
	fs.move(path, "temp.rbxm", true)
	local pathSegments = path:split("/")
	local name = table.remove(pathSegments, #pathSegments)
	assert(name, `bad file name`)
	name = name:gsub("%prbxm", "")
	local baseDir = table.concat(pathSegments, "/")

	unpackInst(baseDir, name, rbxmArray[1], depth)
	fs.removeFile("temp.rbxm")
end
local function parseDirectory(path: string, depth: number)
	for i, v in fs.readDir(path) do
		local childPath = path .. "/" .. v
		if fs.isDir(childPath) then
			parseDirectory(childPath, depth + 1)
		elseif childPath:find("%prbxm") then
			parseFile(childPath, depth + 1)
		end
	end
end
if fs.isFile(PATH) then
	parseFile(PATH, 0)
elseif fs.isDir(PATH) then
	parseDirectory(PATH, -1)
else
	print(`no file or directory found at "{PATH}"`)
end
print("unpack complete")
process.exit(0)