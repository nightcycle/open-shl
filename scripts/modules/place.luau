--!strict
-- what the export tools share: how an instance of a place file is named on a command line, what's never taken out of
-- one + how the scripts are left behind
-- Services
local fs = require("@lune/fs")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
-- Packages
-- Modules
-- Types
-- one step of an instance path. without an index it stands for every sibling of that name
export type Segment = {
	name: string,
	index: number?,
}
export type StrippedScript = {
	path: string,
	className: string,
	lineCount: number,
	isDisabled: boolean,
	linkedSource: string,
	hash: string,
}
-- the scripts somebody read, by the hash of what they hold
export type KnownScripts = { [string]: true }
-- Constants
local PATH_DELIMITER = "/"
local INDEX_DELIMITER = "#"
-- a name can hold the delimiters of a path, in one they're spelled the way a url spells them
local ESCAPES: { [string]: string } = {
	["%2F"] = "/",
	["%2f"] = "/",
	["%23"] = "#",
	["%25"] = "%",
}
local UNESCAPES: { [string]: string } = {
	["/"] = "%2F",
	["#"] = "%23",
	["%"] = "%25",
}
-- nothing of a game goes there + studio doesn't list them, which is how a backdoor rides along in a place file
local CSG_SERVICE_CLASS_NAMES = { "CSGDictionaryService", "NonReplicatedCSGDictionaryService" }
local HASH_LENGTH = 16
-- how lune's xml writes the asset of a union in the newer of its two forms + in the older one
local UNION_CLASS_NAMES = { "UnionOperation", "NegateOperation", "IntersectOperation", "PartOperation" }
local CONTENT_TAG = '<Content name="Content">'
local CONTENT_PATTERN = '<Content name="Content">%s*<uri>(.-)</uri>%s*</Content>'
local EMPTY_CONTENT_PATTERN = '<Content name="Content">%s*<null>%s*</null>%s*</Content>'
local ASSET_ID_TAG = '<ContentId name="AssetId">'
local ASSET_ID_REPLACEMENT = '<ContentId name="AssetId"><url>%1</url></ContentId>'
local EMPTY_ASSET_ID_REPLACEMENT = '<ContentId name="AssetId"><null></null></ContentId>'
local ITEM_PATTERN = '<Item class="([^"]+)" referent="[^"]+">%s*<Properties>(.-)</Properties>'
local KNOWN_SCRIPTS_HEADER = "hash"
local COLUMN_DELIMITER = "\t"
-- Variables
-- References
-- Private Functions
local function unescape(text: string): string
	return (text:gsub("%%%x%x", function(code: string): string
		return ESCAPES[code] or code
	end))
end

local function readProperty(inst: roblox.Instance, name: string): unknown
	-- lune's instance typedef leaves the properties out on purpose
	local ok, value = pcall(function(): unknown
		return ((inst :: unknown) :: { [string]: unknown })[name]
	end)
	return if ok then value else nil
end
-- Class
local Module = {}

Module.PATH_DELIMITER = PATH_DELIMITER

Module.escape = function(name: string): string
	return (name:gsub("[/#%%]", UNESCAPES))
end

-- "game/Workspace/Map" and "Workspace/Map" are the same path
Module.parsePath = function(instPath: string): { Segment }
	local segments: { Segment } = {}
	for index, text in instPath:split(PATH_DELIMITER) do
		if text == "" or (index == 1 and text == "game") then
			continue
		end
		local name, order = text:match(`^(.*){INDEX_DELIMITER}(%d+)$`)
		if name and order then
			table.insert(segments, { name = unescape(name), index = assert(tonumber(order)) })
		else
			assert(not text:find(INDEX_DELIMITER, 1, true), `"{text}" of "{instPath}" has an index that isn't a number`)
			table.insert(segments, { name = unescape(text) })
		end
	end
	return segments
end

Module.getNamed = function(parent: roblox.Instance, name: string): { roblox.Instance }
	local out: { roblox.Instance } = {}
	for _, child in parent:GetChildren() do
		if child.Name == name then
			table.insert(out, child)
		end
	end
	return out
end

-- the path that finds the instance again, a sibling that shares its name is told apart by its place among them
Module.getPath = function(root: roblox.Instance, inst: roblox.Instance): string
	local names: { string } = {}
	local current: roblox.Instance? = inst
	while current and current ~= root do
		local name = Module.escape(current.Name)
		local parent = current.Parent
		if parent then
			local siblings = Module.getNamed(parent, current.Name)
			if #siblings > 1 then
				name ..= `{INDEX_DELIMITER}{assert(table.find(siblings, current))}`
			end
		end
		table.insert(names, 1, name)
		current = parent
	end
	return table.concat(names, PATH_DELIMITER)
end

-- one instance + no other: a name that several siblings share has to say which of them it means
Module.findInstance = function(place: roblox.DataModel, instPath: string): roblox.Instance
	local inst: roblox.Instance = place
	local segments = Module.parsePath(instPath)
	assert(#segments > 0, `"{instPath}" isn't an instance path`)
	for _, segment in segments do
		local named = Module.getNamed(inst, segment.name)
		assert(#named > 0, `No instance at "{segment.name}" in "{instPath}"`)
		if segment.index then
			inst = assert(
				named[segment.index],
				`"{segment.name}" of "{instPath}" has {#named} sibling(s) of that name, not {segment.index}`
			)
		else
			assert(
				#named == 1,
				`"{segment.name}" of "{instPath}" is the name of {#named} siblings, `
					.. `say which with "{Module.escape(segment.name)}{INDEX_DELIMITER}1" to `
					.. `"{Module.escape(segment.name)}{INDEX_DELIMITER}{#named}"`
			)
			inst = named[1]
		end
	end
	return inst
end

-- why an instance is never taken out of a place, nil for one that may be. a service can be renamed, its class can't
Module.getRefusal = function(place: roblox.DataModel, inst: roblox.Instance): string?
	local dataModel: roblox.Instance = place
	if inst == dataModel then
		return "a whole place is never exported"
	end
	if inst.Parent == dataModel then
		return `"{inst.Name}" is a service, which is never exported whole: name what's wanted inside of it`
	end
	local service: roblox.Instance = inst
	while service.Parent and service.Parent ~= dataModel do
		service = service.Parent
	end
	if table.find(CSG_SERVICE_CLASS_NAMES, service.ClassName) then
		return `nothing is exported out of {service.ClassName}`
	end
	return nil
end

Module.getIfFileName = function(name: string): boolean
	return name ~= "" and name ~= "." and name ~= ".." and not name:find('[/\\:*?"<>|]')
end

Module.getScriptHash = function(source: string, linkedSource: string): string
	-- a linked script only holds what the file cached of it, so where it's linked to is part of what it is
	return serde.hash("sha256", `{linkedSource}\n{source}`):sub(1, HASH_LENGTH)
end

-- a tracked table of the scripts somebody read, the first column of a row is the hash of one
Module.readKnownScripts = function(path: string): KnownScripts
	assert(fs.isFile(path), `No list of known scripts at "{path}"`)
	local known: KnownScripts = {}
	for _, line in fs.readFile(path):split("\n") do
		local hash = line:gsub("\r", ""):split(COLUMN_DELIMITER)[1]
		if hash ~= "" and hash ~= KNOWN_SCRIPTS_HEADER then
			assert(#hash == HASH_LENGTH and hash:match("^%x+$"), `"{hash}" of "{path}" isn't the hash of a script`)
			known[hash] = true
		end
	end
	return known
end

Module.listScripts = function(root: roblox.Instance): { StrippedScript }
	local scripts: { StrippedScript } = {}
	for _, desc in root:GetDescendants() do
		if not desc:IsA("LuaSourceContainer") then
			continue
		end
		local source = readProperty(desc, "Source")
		local linkedSource = readProperty(desc, "LinkedSource")
		local sourceText = if type(source) == "string" then source else ""
		local linkedText = if linkedSource == nil then "" else tostring(linkedSource)
		table.insert(scripts, {
			path = Module.getPath(root, desc),
			className = desc.ClassName,
			lineCount = #sourceText:split("\n"),
			isDisabled = readProperty(desc, "Disabled") == true,
			linkedSource = linkedText,
			hash = Module.getScriptHash(sourceText, linkedText),
		})
	end
	return scripts
end

-- only the instances are wanted, the scripts are left behind + whatever is parented under one goes with it. with a
-- list of known scripts nothing is taken off as long as there's one on it that nobody read
Module.stripScripts = function(root: roblox.Instance, known: KnownScripts?): { StrippedScript }
	assert(not root:IsA("LuaSourceContainer"), `"{root.Name}" is a script, there would be nothing left to export`)
	local stripped = Module.listScripts(root)
	if known then
		local unknown: { string } = {}
		for _, strippedScript in stripped do
			if not known[strippedScript.hash] then
				table.insert(unknown, `{strippedScript.hash} {strippedScript.className} "{strippedScript.path}"`)
			end
		end
		assert(
			#unknown == 0,
			`{#unknown} script(s) aren't on the list of known scripts, read them before adding them:\n`
				.. table.concat(unknown, "\n")
		)
	end
	-- a script inside of a script goes down with it + can't be read afterwards, so nothing is destroyed until all
	-- are found
	local scripts: { roblox.Instance } = {}
	for _, desc in root:GetDescendants() do
		if desc:IsA("LuaSourceContainer") then
			table.insert(scripts, desc)
		end
	end
	for _, inst in scripts do
		inst:Destroy()
	end
	return stripped
end

Module.getStrippedReport = function(stripped: { StrippedScript }): string
	local lines: { string } =
		{ table.concat({ "hash", "class", "lines", "state", "linked", "path" }, COLUMN_DELIMITER) }
	for _, strippedScript in stripped do
		table.insert(
			lines,
			table.concat({
				strippedScript.hash,
				strippedScript.className,
				tostring(strippedScript.lineCount),
				if strippedScript.isDisabled then "disabled" else "enabled",
				strippedScript.linkedSource,
				strippedScript.path,
			}, COLUMN_DELIMITER)
		)
	end
	return table.concat(lines, "\n") .. "\n"
end

-- a model as the bytes of an .rbxm + how many unions were rewritten on the way. a union doesn't hold its geometry, it
-- names the asset that does: in a string (AssetId) in every file lib has so far, in a content in a place that a newer
-- studio saved. a build that holds both forms gives every union both, one of them empty, and nobody has seen what
-- studio makes of that. so a union leaves the tools the way the rest of lib names its asset. lune has no name for the
-- newer property, which is why it's swapped in xml: a model comes back from lune's xml byte for byte
Module.serialize = function(inst: roblox.Instance): (string, number)
	local xml = roblox.serializeModel({ inst }, true)
	if not xml:find(CONTENT_TAG, 1, true) then
		return roblox.serializeModel({ inst }), 0
	end
	for className, block in xml:gmatch(ITEM_PATTERN) do
		local hasContent = block:find(CONTENT_TAG, 1, true) ~= nil
		assert(
			not hasContent or table.find(UNION_CLASS_NAMES, className) ~= nil,
			`a {className} of "{inst.Name}" has a property named Content, only a union is known to`
		)
		assert(
			not hasContent or block:find(ASSET_ID_TAG, 1, true) == nil,
			`a {className} of "{inst.Name}" names its asset in both forms`
		)
	end
	local count, emptyCount
	xml, count = xml:gsub(CONTENT_PATTERN, ASSET_ID_REPLACEMENT)
	xml, emptyCount = xml:gsub(EMPTY_CONTENT_PATTERN, EMPTY_ASSET_ID_REPLACEMENT)
	assert(not xml:find(CONTENT_TAG, 1, true), `a union of "{inst.Name}" names its asset in a way that isn't known`)
	return roblox.serializeModel(roblox.deserializeModel(xml)), count + emptyCount
end

-- what a file that was written holds, read back off the disk: a script that made it there fails the export
Module.countWritten = function(path: string): number
	local count = 0
	for _, root in roblox.deserializeModel(fs.readFile(path)) do
		local instances = root:GetDescendants()
		table.insert(instances, root)
		for _, inst in instances do
			assert(not inst:IsA("LuaSourceContainer"), `{inst.ClassName} "{inst.Name}" made it into "{path}"`)
		end
		count += #instances
	end
	return count
end

return Module
