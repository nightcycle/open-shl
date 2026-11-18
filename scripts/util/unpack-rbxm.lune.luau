--!strict
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")

local rojo = require("../modules/rojo")
local rojoValue = require("../modules/rojo-value")

type Property = {
	name: string,
	datatype: string,
	value: rojo.StrictPropertyValue?,
	isEmpty: boolean?,
	-- What the file writes for a plain number or boolean, for a property Lune has no name for.
	written: rojo.StrictPropertyValue?,
}
type PropertiesByInstance = { [roblox.Instance]: { Property } }
type Output = { path: string, contents: string }

local function parseArgs(args: { string }): (string, boolean, boolean, { [string]: boolean })
	local usage = "Usage: lune run scripts/util/unpack-rbxm <file.rbxm or directory> [--recursive | -r] "
		.. "[--whole-duplicates | -w] [--whole <Path/Below/The/Root>]"
	local path: string? = nil
	local recursive = false
	local wholeDuplicates = false
	local wholePaths: { [string]: boolean } = {}
	local isWholePathNext = false
	for _, arg in args do
		if isWholePathNext then
			wholePaths[(arg:gsub("\\", "/"))] = true
			isWholePathNext = false
		elseif arg == "--recursive" or arg == "-r" then
			recursive = true
		elseif arg == "--whole-duplicates" or arg == "-w" then
			wholeDuplicates = true
		elseif arg == "--whole" then
			isWholePathNext = true
		else
			assert(arg:sub(1, 1) ~= "-", `Unknown flag: {arg}\n{usage}`)
			assert(path == nil, `Expected one input path\n{usage}`)
			path = arg
		end
	end
	assert(not isWholePathNext, `Expected a path after --whole\n{usage}`)
	return (assert(path, usage):gsub("\\", "/")), recursive, wholeDuplicates, wholePaths
end

-- WHOLE_PATHS are the instances that stay one rbxm whatever they hold, each named by its path below the root of its
-- file. with WHOLE_DUPLICATES anything whose children share a name stays one as well, so none of them is renamed
local PATH, RECURSIVE, WHOLE_DUPLICATES, WHOLE_PATHS = parseArgs(process.args)
local DATABASE = roblox.getReflectionDatabase()
local XML_TYPES: { [string]: string } = {
	bool = "Bool",
	int = "Int32",
	int64 = "Int64",
	float = "Float32",
	double = "Float64",
	string = "String",
	token = "Enum",
	CoordinateFrame = "CFrame",
	OptionalCoordinateFrame = "OptionalCFrame",
	Content = "ContentId",
}
local SPECIAL_PROPERTIES: { [string]: boolean } = {
	Name = true,
	Parent = true,
	Attributes = true,
	AttributesSerialize = true,
	AttributesReplicate = true,
	Tags = true,
	UniqueId = true,
	HistoryId = true,
	IconTint = true,
	EmissiveMaskContent = true,
	EmissiveStrength = true,
	EmissiveTint = true,
}
local PROPERTY_ALIASES: { [string]: Property } = {}
-- How a property that holds nothing is written: no text at all, or content that points nowhere.
local EMPTY_XML_VALUES: { [string]: boolean } = {
	[""] = true,
	["<null></null>"] = true,
}
local NUMBER_XML_TYPES: { [string]: string } = {
	int = "Int32",
	float = "Float32",
	double = "Float64",
}

local function readProperty(inst: roblox.Instance, name: string): unknown
	-- Lune's Instance typedef intentionally omits dynamic property indexing.
	return ((inst :: unknown) :: { [string]: unknown })[name]
end

local function getPropertyType(className: string, name: string, xmlType: string): string
	local class = DATABASE:GetClass(className)
	while class do
		local property = class.Properties[name]
		if property then
			return property.Datatype
		end
		class = if class.Superclass then DATABASE:GetClass(class.Superclass) else nil
	end
	return XML_TYPES[xmlType] or xmlType
end

local function readableProperty(inst: roblox.Instance, name: string, xmlType: string): Property
	local key = inst.ClassName .. "." .. name
	if PROPERTY_ALIASES[key] then
		return PROPERTY_ALIASES[key]
	end
	local readable = pcall(readProperty, inst, name)
	if readable then
		return { name = name, datatype = getPropertyType(inst.ClassName, name, xmlType) }
	end
	-- Some serialized names (notably Color3uint8) are not indexable in Lune.
	-- Discover their canonical property by serializing one reflected value.
	local class = DATABASE:GetClass(inst.ClassName)
	while class do
		for candidate, descriptor in class.Properties do
			if SPECIAL_PROPERTIES[candidate] then
				continue
			end
			local ok, value = pcall(readProperty, inst, candidate)
			if not ok or value == nil then
				continue
			end
			local probe = roblox.deserializeModel(
				`<roblox version="4"><Item class="{inst.ClassName}"><Properties /></Item></roblox>`
			)[1]
			local written, xml = pcall(function(): string
				((probe :: unknown) :: { [string]: unknown })[candidate] = value
				return roblox.serializeModel({ probe }, true)
			end)
			probe:Destroy()
			if written and string.find(xml, `name="{name}"`, 1, true) then
				local property = { name = candidate, datatype = descriptor.Datatype }
				PROPERTY_ALIASES[key] = property
				return property
			end
		end
		class = if class.Superclass then DATABASE:GetClass(class.Superclass) else nil
	end
	error(`Cannot read serialized property {key}`)
end

local function collectInstances(inst: roblox.Instance, instances: { roblox.Instance })
	table.insert(instances, inst)
	for _, child in inst:GetChildren() do
		collectInstances(child, instances)
	end
end

local function collectProperties(root: roblox.Instance, instances: { roblox.Instance }): PropertiesByInstance
	local properties: PropertiesByInstance = {}
	local index = 0
	-- Reflection does not expose whether a property actually serializes. Ask
	-- Lune's serializer for the stored names, including aliases such as "size".
	-- This XML is generated by Lune (which escapes string values), not parsed
	-- from user-supplied XML. Item/Properties blocks follow depth-first order.
	local xml = roblox.serializeModel({ root }, true)
	local sharedStrings: { [string]: string } = {}
	for hash, value in xml:gmatch('<SharedString md5="([^"]+)">(.-)</SharedString>') do
		assert(hash and value)
		sharedStrings[hash] = value:gsub("%s", "")
	end
	for className, block in xml:gmatch('<Item class="([^"]+)" referent="[^"]+">%s*<Properties>(.-)</Properties>') do
		assert(className and block)
		index += 1
		local inst = instances[index]
		assert(inst and inst.ClassName == className, "Unexpected serialized instance order")
		local list: { Property } = {}
		for xmlType, name, text in block:gmatch('<([%w]+) name="([^"]+)">(.-)</%1>') do
			assert(xmlType and name and text)
			if not SPECIAL_PROPERTIES[name] then
				local property: Property = {
					name = name,
					datatype = getPropertyType(inst.ClassName, name, xmlType),
					isEmpty = EMPTY_XML_VALUES[(text:gsub("%s", ""))] == true,
				}
				if xmlType == "SecurityCapabilities" or xmlType == "int64" then
					-- Keep 64-bit integers as decimal text until JSON encoding, so
					-- values outside Luau's exact integer range are not rounded.
					assert(text:match("^%-?%d+$"), `Invalid integer in {name}`)
					property.value =
						{ [if xmlType == "int64" then "Int64" else xmlType] = text } :: rojo.StrictPropertyValue
				elseif xmlType == "SharedString" or xmlType == "NetAssetRef" then
					property.value =
						{ [xmlType] = assert(sharedStrings[text], `Missing shared string for {name}`) } :: rojo.StrictPropertyValue
				elseif xmlType == "token" then
					property.value =
						{ Enum = assert(tonumber(text), `Invalid enum in {name}`) } :: rojo.StrictPropertyValue
				elseif xmlType == "bool" then
					property.written = { Bool = text == "true" } :: rojo.StrictPropertyValue
				elseif NUMBER_XML_TYPES[xmlType] and tonumber(text) then
					property.written =
						{ [NUMBER_XML_TYPES[xmlType]] = assert(tonumber(text)) } :: rojo.StrictPropertyValue
				end
				table.insert(list, property)
			end
		end
		properties[inst] = list
	end
	assert(index == #instances, "Could not enumerate all serialized instances")
	return properties
end

local function preserveReferences(instances: { roblox.Instance }, properties: PropertiesByInstance, path: string)
	local ids: { [roblox.Instance]: string } = {}
	local prefix = serde.hash("sha256", process.cwd .. "/" .. path):sub(1, 16)
	for index, inst in instances do
		ids[inst] = `unpack-{prefix}-{index}`
	end
	for _, inst in instances do
		for _, property in properties[inst] do
			if property.datatype == "Ref" then
				local target = readProperty(inst, property.name)
				if target ~= nil then
					local targetInst = target :: roblox.Instance
					local id = assert(ids[targetInst], `Reference outside model: {inst.Name}.{property.name}`)
					local existingId = targetInst:GetAttribute("Rojo_Id")
					if existingId ~= nil then
						assert(type(existingId) == "string", "Rojo_Id must be a string")
						id = existingId
					else
						targetInst:SetAttribute("Rojo_Id", id)
					end
					local attribute = `Rojo_Target_{property.name}`
					local existingTarget = inst:GetAttribute(attribute)
					assert(existingTarget == nil or existingTarget == id, `Conflicting reference attribute {attribute}`)
					inst:SetAttribute(attribute, id)
				end
			end
		end
	end
end

local function nodeProperties(inst: roblox.Instance, stored: { Property }): rojo.NodeProperties
	local properties: rojo.NodeProperties = {}
	for _, storedProperty in stored do
		if storedProperty.value then
			properties[storedProperty.name] = storedProperty.value
			continue
		end
		if storedProperty.datatype == "Ref" then
			continue -- Rojo_Target_* attributes resolve references across output files.
		end
		local isReadable, readable = pcall(readableProperty, inst, storedProperty.name, storedProperty.datatype)
		if not isReadable and storedProperty.isEmpty then
			-- Lune has no name for it (Lighting.SerializedOverrides) and the file stores nothing in it.
			print(`left out {inst.ClassName}.{storedProperty.name}: it's empty and Lune can't read it`)
			continue
		end
		if not isReadable and storedProperty.written then
			-- Newer than Lune's database (ColorCorrectionEffect.ColorLutIntensity), the file says all there is.
			print(`took {inst.ClassName}.{storedProperty.name} as the file writes it: Lune can't read it`)
			properties[storedProperty.name] = storedProperty.written
			continue
		end
		assert(isReadable, readable)
		local property = readable :: Property
		local ok, value = pcall(readProperty, inst, property.name)
		assert(ok, `Cannot read {inst.ClassName}.{property.name}: {tostring(value)}`)
		if value ~= nil then
			local converted, result = pcall(rojoValue.toValue, value, property.datatype)
			assert(converted, `Cannot serialize {inst.ClassName}.{property.name}: {tostring(result)}`)
			properties[property.name] = result
		elseif property.datatype == "PhysicalProperties" then
			properties[property.name] = { PhysicalProperties = "Default" }
		end
	end
	local attributes: { [string]: rojo.StrictPropertyValue } = {}
	for name, value in inst:GetAttributes() do
		local ok, result = pcall(rojoValue.toValue, value)
		assert(ok, `Cannot serialize attribute {inst.Name}.{name}: {tostring(result)}`)
		attributes[name] = result
	end
	if next(attributes) then
		properties.Attributes = { Attributes = attributes }
	end
	local tags = inst:GetTags()
	if #tags > 0 then
		table.sort(tags)
		properties.Tags = tags
	end
	return properties
end

local function getIfFileName(name: string): boolean
	return name ~= "" and name ~= "." and name ~= ".." and not name:find('[/\\:*?"<>|]')
end

-- why an instance isn't split into a file per child, nil for one that can be. rojo names an instance after its file:
-- a child whose name can't be a file name has no file to be, and of two that share a name one would be renamed
local function getWholeReason(inst: roblox.Instance, instPath: string): string?
	if WHOLE_PATHS[instPath] then
		return "it's named by --whole"
	end
	local counts: { [string]: number } = {}
	for _, child in inst:GetChildren() do
		if not getIfFileName(child.Name) then
			return `"{child.Name}" can't be a file name`
		end
		counts[child.Name:lower()] = (counts[child.Name:lower()] or 0) + 1
	end
	if WHOLE_DUPLICATES then
		for _, child in inst:GetChildren() do
			if counts[child.Name:lower()] > 1 then
				return `{counts[child.Name:lower()]} of its children are named "{child.Name}"`
			end
		end
	end
	return nil
end

local function unpackInst(
	dir: string,
	name: string,
	inst: roblox.Instance,
	depth: number,
	instPath: string,
	properties: PropertiesByInstance,
	directories: { string },
	outputs: { Output }
)
	assert(getIfFileName(name), `Invalid filename: {name}`)
	local path = dir .. "/" .. name
	local children = inst:GetChildren()
	local wholeReason = if #children > 0 then getWholeReason(inst, instPath) else nil
	if #children == 0 then
		local model: rojo.ModelJSON =
			{ ClassName = inst.ClassName, Properties = nodeProperties(inst, properties[inst]) }
		table.insert(outputs, { path = path .. ".model.json", contents = rojoValue.encode(model) })
	elseif
		wholeReason == nil
		and (
			RECURSIVE
			or inst.ClassName == "Folder"
			or inst.ClassName == "Configuration"
			or (depth == 0 and inst.ClassName == "Model")
		)
	then
		table.insert(directories, path)
		local metadata: rojo.MetaJSON =
			{ className = inst.ClassName, properties = nodeProperties(inst, properties[inst]) }
		table.insert(outputs, { path = path .. "/init.meta.json", contents = rojoValue.encode(metadata) })
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
			local childPath = if instPath == "" then child.Name else instPath .. "/" .. child.Name
			unpackInst(path, childName, child, depth + 1, childPath, properties, directories, outputs)
		end
	else
		if wholeReason then
			print(`"{path}" stays one file: {wholeReason}`)
		end
		table.insert(outputs, { path = path .. ".rbxm", contents = roblox.serializeModel({ inst }) })
	end
end

local function parseFile(path: string)
	print(`parsing "{path}"`)
	local roots = roblox.deserializeModel(fs.readFile(path))
	assert(#roots == 1, "multi-header models not supported")
	local root = roots[1]
	local baseDir, filename = path:match("^(.*)/([^/]+)$")
	baseDir = if baseDir == "" then "/" else baseDir or "."
	filename = filename or path
	assert(baseDir and filename)
	local name, replacements = filename:gsub("%.[rR][bB][xX][mM]$", "")
	assert(replacements == 1, `Expected an .rbxm file: {path}`)
	local instances: { roblox.Instance } = {}
	collectInstances(root, instances)
	local properties = collectProperties(root, instances)
	preserveReferences(instances, properties, path)
	local directories: { string } = {}
	local outputs: { Output } = {}
	unpackInst(baseDir, name, root, 0, "", properties, directories, outputs)
	if #outputs == 1 and outputs[1].path == baseDir .. "/" .. filename then
		return -- This non-leaf instance is already in the desired binary format.
	end
	-- Finish conversion and reject collisions before touching the source file.
	local planned: { [string]: boolean } = {}
	for _, directory in directories do
		assert(not planned[directory:lower()], `Conflicting output path: {directory}`)
		planned[directory:lower()] = true
		assert(not fs.isDir(directory) and not fs.isFile(directory), `Output already exists: {directory}`)
	end
	for _, output in outputs do
		assert(not planned[output.path:lower()], `Conflicting output path: {output.path}`)
		planned[output.path:lower()] = true
		assert(not fs.isFile(output.path) and not fs.isDir(output.path), `Output already exists: {output.path}`)
	end
	for _, directory in directories do
		fs.writeDir(directory)
	end
	for _, output in outputs do
		fs.writeFile(output.path, output.contents)
	end
	fs.removeFile(path)
end

local function parseDirectory(path: string)
	local entries = fs.readDir(path)
	table.sort(entries)
	for _, entry in entries do
		local childPath = path .. "/" .. entry
		if fs.isDir(childPath) then
			parseDirectory(childPath)
		elseif entry:lower():match("%.rbxm$") then
			parseFile(childPath)
		end
	end
end

if fs.isFile(PATH) then
	parseFile(PATH)
elseif fs.isDir(PATH) then
	parseDirectory(PATH)
else
	error(`No file or directory found at "{PATH}"`)
end
print("unpack complete")
