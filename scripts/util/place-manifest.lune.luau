--!strict
-- lists every instance of a place file next to a hash of what it holds, so two builds can be compared without opening
-- either. a step that only moves code around is proven by the place coming out the same before + after
-- Services
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
-- Packages
-- Modules
-- Types
type Row = {
	path: string,
	className: string,
	propertyHash: string,
	sourceHash: string,
}
-- a property that points at something else in the file, which can't be filled in until all of it is read
type Lookup = {
	prefix: string,
	isRef: boolean,
	key: string,
}
type Entry = {
	path: string,
	className: string,
	sourceHash: string,
	properties: { string },
	lookups: { Lookup },
	childCounts: { [string]: number },
}
-- one line of a diff + how many instances it stands for
type Change = {
	path: string,
	note: string,
	count: number,
}
type ServiceChanges = {
	added: { Change },
	removed: { Change },
	changed: { Change },
}
-- Constants
local USAGE = "Usage: lune run scripts/util/place-manifest.lune.luau manifest <place.rbxl> <out.tsv>\n"
	.. "       lune run scripts/util/place-manifest.lune.luau diff <a.tsv or .rbxl> <b.tsv or .rbxl> [--full | -f]"
local PATH_DELIMITER = "/"
local ESCAPE = "\\"
-- a name can hold anything, the delimiter + what would break a row included
local NAME_ESCAPES: { [string]: string } = {
	["\\"] = "\\\\",
	["/"] = "\\/",
	["["] = "\\[",
	["\t"] = "\\t",
	["\n"] = "\\n",
	["\r"] = "\\r",
}
local HEADER = "path\tclass\tproperties\tsource"
local COLUMN_DELIMITER = "\t"
local NO_SOURCE = "-"
local FIELD_DELIMITER = "\0"
-- rolled anew by whatever writes the file, so they say nothing about what's in it
local VOLATILE_PROPERTIES: { [string]: boolean } = {
	UniqueId = true,
	HistoryId = true,
}
-- their value is a key into the strings at the end of the file, which is only as stable as whoever made it up
local SHARED_TYPES: { [string]: boolean } = {
	SharedString = true,
	NetAssetRef = true,
}
local CDATA_OPEN = "<![CDATA["
local CDATA_CLOSE = "]]>"
local CHANGE_KINDS: { { key: "added" | "removed" | "changed", symbol: string } } = {
	{ key = "added", symbol = "+" },
	{ key = "removed", symbol = "-" },
	{ key = "changed", symbol = "~" },
}
-- Variables
-- References
-- Private Functions
local function parseArgs(args: { string }): (string, string, string, boolean)
	local words: { string } = {}
	local isFull = false
	for _, arg in args do
		if arg == "--full" or arg == "-f" then
			isFull = true
		else
			assert(arg:sub(1, 1) ~= "-", `Unknown flag: {arg}\n{USAGE}`)
			table.insert(words, (arg:gsub("\\", "/")))
		end
	end
	assert(#words == 3, `Expected a command and two paths\n{USAGE}`)
	assert(words[1] == "manifest" or words[1] == "diff", `Unknown command: {words[1]}\n{USAGE}`)
	return words[1], words[2], words[3], isFull
end

local function getHash(text: string): string
	return serde.hash("sha256", text)
end

local function escapeName(name: string): string
	return (string.gsub(name, "[\\/%[\t\n\r]", NAME_ESCAPES))
end

-- where the next delimiter that's not part of a name is
local function findDelimiter(path: string, from: number): number?
	local cursor = from
	while true do
		local at = string.find(path, "[\\/]", cursor)
		if at == nil then
			return nil
		end
		if string.sub(path, at, at) == PATH_DELIMITER then
			return at
		end
		cursor = at + #ESCAPE + 1
	end
end

local function getServiceName(path: string): string
	local at = findDelimiter(path, 1)
	return if at then string.sub(path, 1, at - 1) else path
end

local function getParentPath(path: string): string?
	local last: number? = nil
	local at = findDelimiter(path, 1)
	while at do
		last = at
		at = findDelimiter(path, at + 1)
	end
	return if last then string.sub(path, 1, last - 1) else nil
end

local function collectInstances(inst: roblox.Instance, instances: { roblox.Instance })
	table.insert(instances, inst)
	for _, child in inst:GetChildren() do
		collectInstances(child, instances)
	end
end

local function getSourceHash(inst: roblox.Instance): string
	if not inst:IsA("LuaSourceContainer") then
		return NO_SOURCE
	end
	-- lune's Instance type leaves out indexing by property name
	local source = ((inst :: unknown) :: { [string]: unknown }).Source
	return getHash(if type(source) == "string" then source else "")
end

-- a value made of tags is indented by how deep its instance sits, which says nothing about the value
local function getValue(text: string): string
	if string.find(text, "^%s*<") == nil or string.find(text, "^%s*<!%[CDATA%[") ~= nil then
		return text
	end
	local value = string.gsub(text, ">%s+<", "><")
	return string.match(value, "^%s*(.-)%s*$") or value
end

-- whatever sits in a cdata block is text, however much it looks like a tag. where the next block starts is handed
-- back, so it isn't searched for again by every property ahead of it
local function findClose(xml: string, tag: string, from: number, cdataFrom: number): (number, number, number)
	local closing = `</{tag}>`
	local cursor = from
	local cdataStart = cdataFrom
	while true do
		local closeStart, closeEnd = string.find(xml, closing, cursor, true)
		assert(closeStart and closeEnd, `No end to the <{tag}> at {from}`)
		if cdataStart < cursor then
			cdataStart = string.find(xml, CDATA_OPEN, cursor, true) or math.huge
		end
		if cdataStart > closeStart then
			return closeStart, closeEnd, cdataStart
		end
		local _, cdataEnd = string.find(xml, CDATA_CLOSE, cdataStart, true)
		assert(cdataEnd, `No end to the cdata at {cdataStart}`)
		cursor = cdataEnd + 1
	end
end

local function readProperties(xml: string, from: number, cdataFrom: number, entry: Entry): (number, number)
	local cursor = from
	local cdataStart = cdataFrom
	local isScript = entry.sourceHash ~= NO_SOURCE
	while true do
		local _, openEnd, tag, name, slash = string.find(xml, '^%s*<([%w_]+) name="([^"]*)"%s*(/?)>', cursor)
		if openEnd == nil then
			break
		end
		assert(type(tag) == "string" and type(name) == "string", `Unexpected property at {cursor}`)
		local text = ""
		cursor = openEnd + 1
		if slash == "" then
			local closeStart, closeEnd
			closeStart, closeEnd, cdataStart = findClose(xml, tag, cursor, cdataStart)
			text = string.sub(xml, cursor, closeStart - 1)
			cursor = closeEnd + 1
		end
		-- the name is in the path already + the source of a script gets a hash of its own
		if VOLATILE_PROPERTIES[name] or tag == "UniqueId" or name == "Name" or (isScript and name == "Source") then
			continue
		end
		local prefix = `{name}{FIELD_DELIMITER}{tag}{FIELD_DELIMITER}`
		if tag == "Ref" or SHARED_TYPES[tag] then
			table.insert(entry.lookups, { prefix = prefix, isRef = tag == "Ref", key = text })
		else
			table.insert(entry.properties, prefix .. getValue(text))
		end
	end
	local _, closeEnd = string.find(xml, "^%s*</Properties>", cursor)
	assert(closeEnd, `No end to the properties of "{entry.path}"`)
	return closeEnd + 1, cdataStart
end

local function readSharedStrings(xml: string, from: number, hashes: { [string]: string }): number
	local cursor = from
	while true do
		local _, openEnd, key = string.find(xml, '^%s*<SharedString md5="([^"]*)"%s*>', cursor)
		if openEnd == nil then
			break
		end
		assert(type(key) == "string", `Unexpected shared string at {cursor}`)
		local closeStart, closeEnd = string.find(xml, "</SharedString>", openEnd + 1, true)
		assert(closeStart and closeEnd, `No end to the shared string "{key}"`)
		hashes[key] = getHash((string.gsub(string.sub(xml, openEnd + 1, closeStart - 1), "%s", "")))
		cursor = closeEnd + 1
	end
	local _, closeEnd = string.find(xml, "^%s*</SharedStrings>", cursor)
	assert(closeEnd, "No end to the shared strings")
	return closeEnd + 1
end

local function getRows(place: roblox.DataModel): { Row }
	local instances: { roblox.Instance } = {}
	for _, service in place:GetChildren() do
		collectInstances(service, instances)
	end
	-- lune reads a property by name, it can't list the ones an instance was saved with. its xml does + writes the
	-- instances in the same depth-first order, so the two are walked side by side
	local xml = roblox.serializePlace(place, true)
	local entries: { Entry } = {}
	local stack: { Entry } = {}
	local serviceCounts: { [string]: number } = {}
	local pathsByReferent: { [string]: string } = {}
	local hashesBySharedKey: { [string]: string } = {}
	local cursor = 1
	local cdataStart = 0
	while true do
		local _, tagEnd, slash, tag = string.find(xml, "^%s*<(/?)([%w_]+)", cursor)
		assert(tagEnd and type(tag) == "string", `Unexpected xml at {cursor}: {string.sub(xml, cursor, cursor + 80)}`)
		local isClosing = slash == "/"
		local _, openEnd, selfClose = string.find(xml, "^%s*(/?)>", tagEnd + 1)
		if tag == "roblox" and isClosing then
			break
		elseif tag == "roblox" then
			local _, headEnd = string.find(xml, "^[^>]*>", tagEnd + 1)
			cursor = assert(headEnd, "No end to the head of the file") + 1
		elseif tag == "Item" and isClosing then
			assert(openEnd and #stack > 0, `Unexpected end of an instance at {cursor}`)
			table.remove(stack)
			cursor = openEnd + 1
		elseif tag == "Item" then
			local _, itemEnd, className, referent =
				string.find(xml, '^ class="([^"]*)" referent="([^"]*)"%s*>', tagEnd + 1)
			assert(itemEnd and type(referent) == "string", `Unexpected instance at {cursor}`)
			local inst = instances[#entries + 1]
			assert(inst and inst.ClassName == className, "Unexpected serialized instance order")
			local parent: Entry? = stack[#stack]
			local counts = if parent then parent.childCounts else serviceCounts
			local name = escapeName(inst.Name)
			local count = (counts[name] or 0) + 1
			counts[name] = count
			-- siblings can share a name, all but the first are numbered by the order they're in
			local segment = if count > 1 then `{name}[{count}]` else name
			local entry: Entry = {
				path = if parent then parent.path .. PATH_DELIMITER .. segment else segment,
				className = inst.ClassName,
				sourceHash = getSourceHash(inst),
				properties = {},
				lookups = {},
				childCounts = {},
			}
			pathsByReferent[referent] = entry.path
			table.insert(entries, entry)
			table.insert(stack, entry)
			cursor = itemEnd + 1
		elseif tag == "Properties" and not isClosing then
			local entry = assert(stack[#stack], `Properties outside of an instance at {cursor}`)
			assert(openEnd, `Unexpected properties at {cursor}`)
			cursor = openEnd + 1
			if selfClose == "" then
				cursor, cdataStart = readProperties(xml, cursor, cdataStart, entry)
			end
		elseif tag == "SharedStrings" and not isClosing then
			assert(openEnd, `Unexpected shared strings at {cursor}`)
			cursor = openEnd + 1
			if selfClose == "" then
				cursor = readSharedStrings(xml, cursor, hashesBySharedKey)
			end
		else
			error(`Unexpected <{slash}{tag}> at {cursor}`)
		end
	end
	assert(#stack == 0 and #entries == #instances, "The xml doesn't hold the instances the place does")

	local rows: { Row } = {}
	for _, entry in entries do
		for _, lookup in entry.lookups do
			-- a reference is only the same between two files by where it leads
			local value = if lookup.isRef then pathsByReferent[lookup.key] else hashesBySharedKey[lookup.key]
			table.insert(entry.properties, lookup.prefix .. (value or lookup.key))
		end
		table.sort(entry.properties)
		table.insert(rows, {
			path = entry.path,
			className = entry.className,
			propertyHash = getHash(table.concat(entry.properties, "\n")),
			sourceHash = entry.sourceHash,
		})
	end
	table.sort(rows, function(a: Row, b: Row): boolean
		return a.path < b.path
	end)
	return rows
end

local function readManifest(path: string): { Row }
	local lines = string.split((string.gsub(fs.readFile(path), "\r\n", "\n")), "\n")
	assert(lines[1] == HEADER, `"{path}" isn't a manifest`)
	local rows: { Row } = {}
	for index = 2, #lines do
		local line = lines[index]
		if line == "" then
			continue
		end
		local fields = string.split(line, COLUMN_DELIMITER)
		assert(#fields == 4, `Line {index} of "{path}" isn't a row of a manifest`)
		table.insert(rows, {
			path = fields[1],
			className = fields[2],
			propertyHash = fields[3],
			sourceHash = fields[4],
		})
	end
	return rows
end

-- a place is as good as its manifest, which saves writing one out only to compare it
local function readRows(path: string): { Row }
	assert(fs.isFile(path), `No file found at "{path}"`)
	if path:lower():match("%.rbxlx?$") then
		return getRows(roblox.deserializePlace(fs.readFile(path)))
	end
	return readManifest(path)
end

local function getRowsByPath(rows: { Row }): { [string]: Row }
	local rowsByPath: { [string]: Row } = {}
	for _, row in rows do
		assert(rowsByPath[row.path] == nil, `Duplicate path: {row.path}`)
		rowsByPath[row.path] = row
	end
	return rowsByPath
end

local function getServiceChanges(changesByService: { [string]: ServiceChanges }, path: string): ServiceChanges
	local serviceName = getServiceName(path)
	local changes = changesByService[serviceName]
	if changes == nil then
		changes = { added = {}, removed = {}, changed = {} }
		changesByService[serviceName] = changes
	end
	return changes
end

-- the rows that the other side has nothing for. a subtree that came or went as a whole is a single line under its
-- root, unless every instance is asked for
local function getMissingChanges(rows: { Row }, others: { [string]: Row }, isFull: boolean): { Change }
	local isMissing: { [string]: boolean } = {}
	for _, row in rows do
		isMissing[row.path] = others[row.path] == nil
	end
	local changes: { Change } = {}
	local changesByRoot: { [string]: Change } = {}
	for _, row in rows do
		if not isMissing[row.path] then
			continue
		end
		local root = row.path
		local parent = if isFull then nil else getParentPath(root)
		while parent and isMissing[parent] do
			root = parent
			parent = getParentPath(root)
		end
		local change = changesByRoot[root]
		if change == nil then
			change = { path = root, note = "", count = 0 }
			changesByRoot[root] = change
			table.insert(changes, change)
		end
		change.count += 1
		if root == row.path then
			change.note = row.className
		end
	end
	for _, change in changes do
		if change.count > 1 then
			change.note ..= ` (+{change.count - 1} inside)`
		end
	end
	return changes
end

local function getChangedNote(a: Row, b: Row): string?
	local notes: { string } = {}
	if a.className ~= b.className then
		table.insert(notes, `{a.className} -> {b.className}`)
	end
	if a.propertyHash ~= b.propertyHash then
		table.insert(notes, "properties")
	end
	if a.sourceHash ~= b.sourceHash then
		table.insert(notes, "source")
	end
	return if #notes > 0 then table.concat(notes, ", ") else nil
end

local function getCount(changes: { Change }): number
	local count = 0
	for _, change in changes do
		count += change.count
	end
	return count
end

-- whether the two are the same
local function printDiff(aRows: { Row }, bRows: { Row }, isFull: boolean): boolean
	local aRowsByPath = getRowsByPath(aRows)
	local bRowsByPath = getRowsByPath(bRows)
	local changesByService: { [string]: ServiceChanges } = {}
	for _, change in getMissingChanges(bRows, aRowsByPath, isFull) do
		table.insert(getServiceChanges(changesByService, change.path).added, change)
	end
	for _, change in getMissingChanges(aRows, bRowsByPath, isFull) do
		table.insert(getServiceChanges(changesByService, change.path).removed, change)
	end
	for _, aRow in aRows do
		local bRow = bRowsByPath[aRow.path]
		local note = if bRow then getChangedNote(aRow, bRow) else nil
		if note then
			local change: Change = { path = aRow.path, note = note, count = 1 }
			table.insert(getServiceChanges(changesByService, change.path).changed, change)
		end
	end

	local serviceNames: { string } = {}
	for serviceName in changesByService do
		table.insert(serviceNames, serviceName)
	end
	table.sort(serviceNames)
	local totals = { added = 0, removed = 0, changed = 0 }
	for _, serviceName in serviceNames do
		local changes = changesByService[serviceName]
		local counts: { string } = {}
		for _, kind in CHANGE_KINDS do
			local count = getCount(changes[kind.key])
			totals[kind.key] += count
			table.insert(counts, `{count} {kind.key}`)
		end
		print(`{serviceName}: {table.concat(counts, ", ")}`)
		for _, kind in CHANGE_KINDS do
			for _, change in changes[kind.key] do
				print(`\t{kind.symbol} {change.path}\t{change.note}`)
			end
		end
	end
	local size = `{#aRows} instances against {#bRows}`
	if #serviceNames == 0 then
		print(`identical: {size}`)
		return true
	end
	print(`different: {totals.added} added, {totals.removed} removed, {totals.changed} changed ({size})`)
	return false
end
-- Class
do
	local command, firstPath, secondPath, isFull = parseArgs(process.args)
	if command == "manifest" then
		assert(fs.isFile(firstPath), `No place file found at "{firstPath}"`)
		local rows = getRows(roblox.deserializePlace(fs.readFile(firstPath)))
		local lines: { string } = { HEADER }
		for _, row in rows do
			table.insert(
				lines,
				table.concat({ row.path, row.className, row.propertyHash, row.sourceHash }, COLUMN_DELIMITER)
			)
		end
		table.insert(lines, "")
		local dir = secondPath:match("^(.*)/[^/]+$")
		if dir and dir ~= "" and not fs.isDir(dir) then
			fs.writeDir(dir)
		end
		fs.writeFile(secondPath, table.concat(lines, "\n"))
		print(`wrote "{secondPath}" ({#rows} instances)`)
	else
		local isSame = printDiff(readRows(firstPath), readRows(secondPath), isFull)
		-- a script that checks a move only has to look at how this ended
		process.exit(if isSame then 0 else 1)
	end
end
