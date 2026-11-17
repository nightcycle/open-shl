--!strict
-- pulls a single instance out of a place file as an rbxm, the output is what unpack-rbxm expects as input
-- Services
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
-- Packages
-- Modules
-- Types
type Output = { path: string, contents: string }
-- Constants
local USAGE = "Usage: lune run scripts/util/export-rbxm.lune.luau <place.rbxl> <Service/Path/To/Instance> "
	.. "<out.rbxm or directory> [--children | -c] [--strip-scripts | -s]"
local PATH_DELIMITER = "/"
-- Variables
-- References
-- Private Functions
local function parseArgs(args: { string }): (string, string, string, boolean, boolean)
	local paths: { string } = {}
	local isSplitByChild = false
	local isScriptStripped = false
	for _, arg in args do
		if arg == "--children" or arg == "-c" then
			isSplitByChild = true
		elseif arg == "--strip-scripts" or arg == "-s" then
			isScriptStripped = true
		else
			assert(arg:sub(1, 1) ~= "-", `Unknown flag: {arg}\n{USAGE}`)
			table.insert(paths, (arg:gsub("\\", "/")))
		end
	end
	assert(#paths == 3, `Expected a place, an instance path and an output path\n{USAGE}`)
	return paths[1], paths[2], paths[3], isSplitByChild, isScriptStripped
end

local function getFullName(root: roblox.Instance, inst: roblox.Instance): string
	local names: { string } = {}
	local current: roblox.Instance? = inst
	while current do
		table.insert(names, 1, current.Name)
		if current == root then
			break
		end
		current = current.Parent
	end
	return table.concat(names, PATH_DELIMITER)
end

local function findInstance(place: roblox.DataModel, instPath: string): roblox.Instance
	local inst: roblox.Instance? = nil
	for index, name in instPath:split(PATH_DELIMITER) do
		-- "game/Workspace/Map" and "Workspace/Map" are the same path
		if name == "" or (index == 1 and name == "game") then
			continue
		end
		local parent: roblox.Instance = inst or place
		inst = assert(parent:FindFirstChild(name), `No instance at "{name}" in "{instPath}"`)
	end
	return assert(inst, `Expected an instance path\n{USAGE}`)
end

local function getIfInsideScript(root: roblox.Instance, inst: roblox.Instance): boolean
	local current: roblox.Instance? = inst.Parent
	while current and current ~= root do
		if current:IsA("LuaSourceContainer") then
			return true
		end
		current = current.Parent
	end
	return false
end

-- only the instances are wanted, scripts get left behind
local function stripScripts(root: roblox.Instance)
	assert(not root:IsA("LuaSourceContainer"), `"{root.Name}" is a script, there would be nothing left to export`)
	-- a script inside of a script goes down with it + can't be read afterwards, so nothing is destroyed until all are found
	local scripts: { roblox.Instance } = {}
	for _, desc in root:GetDescendants() do
		if desc:IsA("LuaSourceContainer") then
			print(`stripped {desc.ClassName} "{getFullName(root, desc)}"`)
			if not getIfInsideScript(root, desc) then
				table.insert(scripts, desc)
			end
		end
	end
	for _, inst in scripts do
		inst:Destroy()
	end
end

local function getChildOutputs(dir: string, inst: roblox.Instance): { Output }
	local outputs: { Output } = {}
	local children = inst:GetChildren()
	-- same duplicate naming as unpack-rbxm, so both tools agree on what a sibling is called
	local reserved: { [string]: boolean } = {}
	local used: { [string]: boolean } = {}
	for _, child in children do
		reserved[child.Name:lower()] = true
	end
	for _, child in children do
		local childName = child.Name
		local suffix = 0
		while used[childName:lower()] do
			repeat
				suffix += 1
				childName = `{child.Name}_{suffix}`
			until not reserved[childName:lower()] and not used[childName:lower()]
		end
		used[childName:lower()] = true
		assert(
			childName ~= "" and childName ~= "." and childName ~= ".." and not childName:find('[/\\:*?"<>|]'),
			`Invalid filename: {childName}`
		)
		table.insert(outputs, {
			path = `{dir}/{childName}.rbxm`,
			contents = roblox.serializeModel({ child }),
		})
	end
	return outputs
end
-- Class
do
	local placePath, instPath, outPath, isSplitByChild, isScriptStripped = parseArgs(process.args)
	assert(fs.isFile(placePath), `No place file found at "{placePath}"`)
	local inst = findInstance(roblox.deserializePlace(fs.readFile(placePath)), instPath)
	if isScriptStripped then
		stripScripts(inst)
	end

	local outputs: { Output }
	local dir: string
	if isSplitByChild then
		dir = outPath
		outputs = getChildOutputs(dir, inst)
		assert(#outputs > 0, `"{instPath}" has no children to export`)
	else
		assert(outPath:lower():match("%.rbxm$"), `Expected an .rbxm output path: {outPath}`)
		local parentDir = outPath:match("^(.*)/[^/]+$")
		dir = if parentDir == "" then "/" else parentDir or "."
		outputs = { { path = outPath, contents = roblox.serializeModel({ inst }) } }
	end

	-- reject collisions before touching the disk
	for _, output in outputs do
		assert(not fs.isFile(output.path) and not fs.isDir(output.path), `Output already exists: {output.path}`)
	end
	if not fs.isDir(dir) then
		fs.writeDir(dir)
	end
	for _, output in outputs do
		fs.writeFile(output.path, output.contents)
		print(`wrote "{output.path}"`)
	end
	print("export complete")
end
