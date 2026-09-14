--!strict
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")

type Properties = { [string]: string }

local TYPES: { [string]: string } = {
	axes = "Axes",
	bool = "boolean",
	boolean = "boolean",
	brickcolor = "BrickColor",
	cframe = "CFrame",
	class = "string",
	color3 = "Color3",
	color3uint8 = "Color3",
	colorsequence = "ColorSequence",
	content = "Content",
	contentid = "Content",
	coordinateframe = "CFrame",
	customphysicalproperties = "PhysicalProperties",
	dictionary = "{ [string]: unknown }",
	double = "number",
	faces = "Faces",
	float = "number",
	float32 = "number",
	float64 = "number",
	font = "Font",
	int = "number",
	int16 = "number",
	int32 = "number",
	int64 = "number",
	number = "number",
	numberrange = "NumberRange",
	numbersequence = "NumberSequence",
	object = "Instance?",
	optionalcframe = "CFrame?",
	optionalcoordinateframe = "CFrame?",
	physicalproperties = "PhysicalProperties",
	ray = "Ray",
	ref = "Instance?",
	region3 = "Region3",
	region3int16 = "Region3int16",
	rect = "Rect",
	string = "string",
	tuple = "{ unknown }",
	udim = "UDim",
	udim2 = "UDim2",
	uint = "number",
	uint16 = "number",
	uint32 = "number",
	uint64 = "number",
	variant = "unknown",
	vector2 = "Vector2",
	vector2int16 = "Vector2int16",
	vector3 = "Vector3",
	vector3int16 = "Vector3int16",
}

local EXCLUDED_TYPES: { [string]: boolean } = {
	binarystring = true,
	protectedstring = true,
	securitycapabilities = true,
	sharedstring = true,
	uniqueid = true,
}

local function luauType(datatype: unknown): string
	local name = tostring(datatype)
	local normalized = string.lower(name)
	local enumName = name:gsub("[^%w_]+$", ""):match("([%w_]+)$")
	if normalized:match("^enum") and enumName and enumName ~= "Enum" and enumName ~= "EnumItem" then
		return `Enum.{enumName}`
	end
	return TYPES[normalized] or "unknown"
end

local function collectProperties(database: any, className: string, cache: { [string]: Properties }): Properties
	if cache[className] then
		return cache[className]
	end

	local class = assert(database:GetClass(className))
	local properties: Properties = {}
	if class.Superclass then
		for name, datatype in collectProperties(database, class.Superclass, cache) do
			properties[name] = datatype
		end
	end

	for name, property in class.Properties do
		local datatype = tostring(property.Datatype)
		if tostring(property.Scriptability) == "ReadWrite" and not EXCLUDED_TYPES[string.lower(datatype)] then
			properties[name] = luauType(property.Datatype)
		end
	end

	cache[className] = properties
	return properties
end

local function makeDirectories(path: string)
	local parent = path:match("^(.*)[/\\][^/\\]+$")
	if parent and parent ~= "" and not parent:match("^%a:$") and not fs.isDir(parent) then
		makeDirectories(parent)
		fs.writeDir(parent)
	end
end

local outputPath = assert(process.args[1])
local className = assert(process.args[2])

local database = roblox.getReflectionDatabase() :: any
local cache: { [string]: Properties } = {}
local lines = {
	"--!strict",
	'local React = require("@game/ReplicatedStorage/Packages/React")',
	"local e = React.createElement",
	"",
}

do
	local properties = collectProperties(database, className, cache)
	local names: { string } = {}
	for name in properties do
		table.insert(names, name)
	end
	table.sort(names)

	table.insert(lines, `export type Properties = \{`)
	for _, name in names do
		table.insert(lines, `\t{name}: {properties[name]}?,`)
	end
	table.insert(lines, "}")
	table.insert(lines, "")
end

table.insert(lines, "")
table.insert(lines, `local function append(defaults: Properties, props: Properties): Properties`)
table.insert(lines, "\tlocal result = {}")
table.insert(lines, "\tfor name, value in props do")
table.insert(lines, "\t\tresult[name] = value")
table.insert(lines, "\tend")
table.insert(lines, "\tfor name, value in defaults do")
table.insert(lines, "\t\tresult[name] = value")
table.insert(lines, "\tend")
table.insert(lines, "\treturn result")
table.insert(lines, "end")
table.insert(lines, "")

do
	table.insert(lines, `return function(defaults: Properties): (Properties) -> React.ReactNode`)
	table.insert(lines, `\treturn function(props: Properties): React.ReactNode`)
	table.insert(lines, `\t\treturn e("{className}", append(defaults, props) :: any, props["children" :: any])`)
	table.insert(lines, "\tend")
	table.insert(lines, "end")
end

makeDirectories(outputPath)
fs.writeFile(outputPath, table.concat(lines, "\n") .. "\n")
