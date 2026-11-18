--!strict
-- moves a batch of legacy images from the staging folder into asset/image. which image belongs to which batch + where
-- it goes is read from asset/legacy-ids.tsv
--
-- asphalt uploads every file its Image input takes + a locked sync, which is what the pipeline builds with, fails on
-- one that has no upload yet. so the folder of a legacy game is left out of the path of that input and each of its
-- files gets a line in the web table of asphalt.toml instead, which names an upload that's there already: the one the
-- legacy game made of it, or the creator's own when the same bytes went up before. the image has its key in
-- Generated/Image without anything being uploaded. a file that lands where the input does take it still needs its
-- upload, nothing is written for it
-- Services
local fs = require("@lune/fs")
local process = require("@lune/process")
local serde = require("@lune/serde")
-- Packages
-- Modules
-- Types
type Row = {
	id: string,
	target: string,
	sha256: string,
	batch: string,
}
-- one file of a batch + the legacy ids it came down as, by the hash each came down with. two ids can hold the same
-- picture encoded twice, the file is what one of them holds
type File = {
	target: string,
	idsByHash: { [string]: string },
}
type FileState = "Missing" | "Unlisted" | "Ready" | "Landed" | "Taken"
type Batch = {
	name: string,
	files: { File },
}
-- the text of asphalt.toml around the lines of its web table, which are kept sorted
type WebTable = {
	head: { string },
	ids: { [string]: string },
	tail: { string },
}
-- Constants
local USAGE = "Usage: lune run scripts/util/import-images.lune.luau list [<staging dir>]\n"
	.. "       lune run scripts/util/import-images.lune.luau land <batch> [<staging dir>] [--dry-run | -d]"
local TABLE_PATH = "asset/legacy-ids.tsv"
local LOCK_PATH = "asphalt.lock.toml"
local CONFIG_PATH = "asphalt.toml"
local IMAGE_ROOT = "asset/image/"
local WEB_HEADER = "[inputs.Image.web]"
local WEB_LINE_PATTERN = '^"(.+)" = { id = (%d+) }$'
local DEFAULT_STAGING_DIR = "staging"
local HEADER = "id\tgames\ttype\ttarget\tsha256\tbatch\tnote"
local COLUMN_DELIMITER = "\t"
local PATH_DELIMITER = "/"
-- the wrapper asphalt is run through, it is printed for whoever owns the upload + never run from here
local UPLOAD_COMMAND = "UPLOAD_ASSETS=true sh scripts/proj/sync.sh"
local SYNC_COMMAND = "sh scripts/proj/sync.sh"
local STATE_NOTES: { [FileState]: string } = {
	Missing = "not in the staging folder",
	Unlisted = "the staged file is not the one the table lists",
	Ready = "",
	Landed = "already there",
	Taken = "a different file is already there",
}
-- Variables
-- References
-- Private Functions
local function parseArgs(args: { string }): (string, string?, string, boolean)
	local words: { string } = {}
	local isDryRun = false
	for _, arg in args do
		if arg == "--dry-run" or arg == "-d" then
			isDryRun = true
		else
			assert(arg:sub(1, 1) ~= "-", `Unknown flag: {arg}\n{USAGE}`)
			table.insert(words, (arg:gsub("\\", "/")))
		end
	end
	local command = words[1]
	if command == "list" then
		assert(#words <= 2, `Expected at most a staging dir\n{USAGE}`)
		return command, nil, words[2] or DEFAULT_STAGING_DIR, isDryRun
	end
	assert(command == "land", `Expected a command\n{USAGE}`)
	assert(#words == 2 or #words == 3, `Expected a batch\n{USAGE}`)
	return command, words[2], words[3] or DEFAULT_STAGING_DIR, isDryRun
end

local function readLines(path: string): { string }
	return fs.readFile(path):gsub("\r", ""):split("\n")
end

local function readRows(): { Row }
	assert(fs.isFile(TABLE_PATH), `no id table at "{TABLE_PATH}", is this the root of the repo?`)
	local lines = readLines(TABLE_PATH)
	assert(lines[1] == HEADER, `"{TABLE_PATH}" starts with a header this tool does not know`)
	local rows: { Row } = {}
	for index, line in lines do
		if index == 1 or line == "" then
			continue
		end
		local cells = line:split(COLUMN_DELIMITER)
		assert(#cells == 7, `line {index} of "{TABLE_PATH}" has {#cells} columns`)
		table.insert(rows, { id = cells[1], target = cells[4], sha256 = cells[5], batch = cells[6] })
	end
	return rows
end

local function getBatches(rows: { Row }): { Batch }
	local batches: { Batch } = {}
	local batchesByName: { [string]: Batch } = {}
	local filesByTarget: { [string]: File } = {}
	for _, row in rows do
		if row.batch == "" then
			continue
		end
		local at = `id {row.id} of "{TABLE_PATH}"`
		-- a path out of the table is never trusted to stay inside the image folder
		assert(row.target:sub(1, #IMAGE_ROOT) == IMAGE_ROOT, `{at} is in a batch but goes outside "{IMAGE_ROOT}"`)
		assert(row.target:find("..", 1, true) == nil, `{at} has a path that climbs`)
		assert(row.sha256 ~= "", `{at} is in a batch but has no hash`)
		local batch = batchesByName[row.batch]
		if batch == nil then
			batch = { name = row.batch, files = {} }
			batchesByName[row.batch] = batch
			table.insert(batches, batch)
		end
		local file = filesByTarget[row.target]
		if file == nil then
			file = { target = row.target, idsByHash = {} }
			filesByTarget[row.target] = file
			table.insert(batch.files, file)
		end
		assert(file.idsByHash[row.sha256] == nil, `{at} came down as the same bytes as id {file.idsByHash[row.sha256]}`)
		file.idsByHash[row.sha256] = row.id
	end
	table.sort(batches, function(a: Batch, b: Batch): boolean
		return a.name < b.name
	end)
	for _, batch in batches do
		table.sort(batch.files, function(a: File, b: File): boolean
			return a.target < b.target
		end)
	end
	return batches
end

local function getState(file: File, stagingDir: string): (FileState, string?)
	local stagedPath = stagingDir .. PATH_DELIMITER .. file.target
	if not fs.isFile(stagedPath) then
		-- a batch that already went in can be thrown out of the staging folder
		return if fs.isFile(file.target) then "Landed" else "Missing", nil
	end
	local contents = fs.readFile(stagedPath)
	if file.idsByHash[serde.hash("sha256", contents)] == nil then
		return "Unlisted", nil
	end
	if not fs.isFile(file.target) then
		return "Ready", contents
	end
	return if fs.readFile(file.target) == contents then "Landed" else "Taken", contents
end

-- the uploads asphalt has, it keys them by the blake3 of the file
local function getLockedIds(): { [string]: string }
	local lockedIds: { [string]: string } = {}
	if not fs.isFile(LOCK_PATH) then
		return lockedIds
	end
	local lock = serde.decode("toml", fs.readFile(LOCK_PATH))
	local inputs = if type(lock) == "table" then lock.inputs else nil
	local images = if type(inputs) == "table" then inputs.Image else nil
	if type(images) == "table" then
		for hash, entry in images do
			lockedIds[hash] = string.format("%d", entry.asset_id)
		end
	end
	return lockedIds
end

local function getLockedId(contents: string, lockedIds: { [string]: string }): string?
	return lockedIds[serde.hash("blake3", contents)]
end

-- the patterns a path is held against to tell whether the Image input of asphalt takes it. only what a path of that
-- input is written with is known here: a list of names in braces, * for anything of a name + ** for anything at all
local function getInputPatterns(): { string }
	local config = serde.decode("toml", fs.readFile(CONFIG_PATH))
	local inputs = if type(config) == "table" then config.inputs else nil
	local image = if type(inputs) == "table" then inputs.Image else nil
	local glob = if type(image) == "table" then image.path else nil
	assert(type(glob) == "string", `"{CONFIG_PATH}" has no path for its Image input`)
	local globs: { string } = { glob }
	local hasBraces = true
	while hasBraces do
		hasBraces = false
		local expanded: { string } = {}
		for _, text in globs do
			local before, names, after = text:match("^(.-){([^{}]*)}(.*)$")
			if before and names and after then
				hasBraces = true
				for _, name in names:split(",") do
					table.insert(expanded, before .. name .. after)
				end
			else
				table.insert(expanded, text)
			end
		end
		globs = expanded
	end
	local patterns: { string } = {}
	for _, text in globs do
		assert(
			text:find("[%[%]?]") == nil,
			`the path of the Image input is written in a way this tool can't read: {glob}`
		)
		-- the deep wildcard is set aside while the plain one is written out, they share their character
		local pattern =
			text:gsub("[%^%$%(%)%%%.%+%-]", "%%%0"):gsub("%*%*/?", "\1"):gsub("%*", "[^/]*"):gsub("\1", ".*")
		table.insert(patterns, `^{pattern}$`)
	end
	return patterns
end

local function getIfTaken(target: string, patterns: { string }): boolean
	for _, pattern in patterns do
		if target:match(pattern) then
			return true
		end
	end
	return false
end

local function readWebTable(): WebTable
	local lines = readLines(CONFIG_PATH)
	if table.find(lines, WEB_HEADER) == nil then
		-- the first image that stands for a legacy upload opens the table
		while lines[#lines] == "" do
			table.remove(lines)
		end
		table.insert(lines, "")
		table.insert(lines, WEB_HEADER)
	end
	local headerIndex = assert(table.find(lines, WEB_HEADER), `"{CONFIG_PATH}" has no {WEB_HEADER}`)
	local webTable: WebTable = { head = table.move(lines, 1, headerIndex, 1, {}), ids = {}, tail = {} }
	local index = headerIndex + 1
	-- the table ends where the next one starts, or the comment above it
	while lines[index] and lines[index]:find("^[%[#]") == nil do
		local line = lines[index]
		local path, id = line:match(WEB_LINE_PATTERN)
		if path and id then
			assert(webTable.ids[path] == nil, `"{path}" is under {WEB_HEADER} of "{CONFIG_PATH}" twice`)
			webTable.ids[path] = id
		else
			-- the table is written over in order, a line that isn't one of its own would be lost on the way
			assert(line == "", `this tool keeps {WEB_HEADER} of "{CONFIG_PATH}" + can't read its line {index}: {line}`)
		end
		index += 1
	end
	table.move(lines, index, #lines, 1, webTable.tail)
	return webTable
end

local function writeWebTable(webTable: WebTable)
	local paths: { string } = {}
	for path in webTable.ids do
		table.insert(paths, path)
	end
	table.sort(paths)
	local lines = table.clone(webTable.head)
	for _, path in paths do
		table.insert(lines, `"{path}" = \{ id = {webTable.ids[path]} }`)
	end
	if #webTable.tail > 0 then
		table.insert(lines, "")
		table.move(webTable.tail, 1, #webTable.tail, #lines + 1, lines)
	elseif lines[#lines] ~= "" then
		table.insert(lines, "")
	end
	fs.writeFile(CONFIG_PATH, table.concat(lines, "\n"))
end

local function getWebPath(target: string): string
	return target:sub(#IMAGE_ROOT + 1)
end

local function makeParentDir(path: string)
	local segments = path:split(PATH_DELIMITER)
	table.remove(segments)
	fs.writeDir(table.concat(segments, PATH_DELIMITER))
end

local function list(batches: { Batch }, stagingDir: string)
	local lockedIds = getLockedIds()
	local webTable = readWebTable()
	print(`batches of "{TABLE_PATH}", staged under "{stagingDir}"`)
	for _, batch in batches do
		local stagedCount, landedCount, lockedCount, webCount, byteCount = 0, 0, 0, 0, 0
		for _, file in batch.files do
			local stagedPath = stagingDir .. PATH_DELIMITER .. file.target
			if fs.isFile(stagedPath) then
				stagedCount += 1
				byteCount += #fs.readFile(stagedPath)
			end
			if fs.isFile(file.target) then
				landedCount += 1
				lockedCount += if getLockedId(fs.readFile(file.target), lockedIds) then 1 else 0
			end
			webCount += if webTable.ids[getWebPath(file.target)] then 1 else 0
		end
		print(
			`  {batch.name}: {#batch.files} files, {stagedCount} staged ({byteCount} bytes), `
				.. `{landedCount} in "{IMAGE_ROOT}", {lockedCount} uploaded, {webCount} under {WEB_HEADER}`
		)
	end
end

local function land(batch: Batch, stagingDir: string, isDryRun: boolean)
	local contentsByTarget: { [string]: string } = {}
	local problemCount, readyCount, landedCount = 0, 0, 0
	print(`{batch.name}: {#batch.files} files from "{stagingDir}"`)
	for _, file in batch.files do
		local state: FileState, contents = getState(file, stagingDir)
		if state == "Ready" and contents then
			contentsByTarget[file.target] = contents
			readyCount += 1
			print(`  + {file.target}`)
		elseif state == "Landed" then
			contentsByTarget[file.target] = contents or fs.readFile(file.target)
			landedCount += 1
			print(`  = {file.target} ({STATE_NOTES[state]})`)
		else
			problemCount += 1
			print(`  ! {file.target} ({STATE_NOTES[state]})`)
		end
	end
	-- a batch goes in whole or not at all, half of one is harder to tell from a finished one
	if problemCount > 0 then
		print(`{problemCount} file(s) can't be copied, nothing was`)
		process.exit(1)
	end

	-- a file that sits where asphalt uploads from is asphalt's: it has its upload or it waits for it. every other one
	-- stands for an upload that's there already, the one its bytes came down from unless the creator has them as well
	local lockedIds = getLockedIds()
	local patterns = getInputPatterns()
	local webTable = readWebTable()
	local webLines: { string } = {}
	local pendingTargets: { string } = {}
	for _, file in batch.files do
		local contents = contentsByTarget[file.target]
		local webPath = getWebPath(file.target)
		local lockedId = getLockedId(contents, lockedIds)
		if getIfTaken(file.target, patterns) then
			if lockedId == nil then
				table.insert(pendingTargets, file.target)
			end
			continue
		end
		local legacyId =
			assert(file.idsByHash[serde.hash("sha256", contents)], `"{file.target}" isn't a file of the table`)
		local id = lockedId or legacyId
		local webId = webTable.ids[webPath]
		assert(webId == nil or webId == id, `"{webPath}" is under {WEB_HEADER} as {webId}, it would be {id} today`)
		if webId == nil then
			webTable.ids[webPath] = id
			local others: { string } = {}
			for _, otherId in file.idsByHash do
				if otherId ~= id then
					table.insert(others, otherId)
				end
			end
			table.sort(others)
			local note = ""
			if lockedId then
				note = `   # the upload "{LOCK_PATH}" has of the same bytes, the legacy one is {legacyId}`
			elseif #others > 0 then
				note = `   # the same picture as {table.concat(others, ", ")}`
			end
			table.insert(webLines, `"{webPath}" = \{ id = {id} }{note}`)
		end
	end

	if not isDryRun then
		for _, file in batch.files do
			if not fs.isFile(file.target) then
				makeParentDir(file.target)
				fs.writeFile(file.target, contentsByTarget[file.target])
			end
		end
		if #webLines > 0 then
			writeWebTable(webTable)
		end
	end
	local verb = if isDryRun then "would copy" else "copied"
	print(`{verb} {readyCount}, {landedCount} already there`)
	if #webLines > 0 then
		local webVerb = if isDryRun then "would get" else "got"
		print(
			`{WEB_HEADER} of "{CONFIG_PATH}" {webVerb} {#webLines} line(s), each names the upload its file stands for:`
		)
		for _, line in webLines do
			print(`  {line}`)
		end
		print(`"{SYNC_COMMAND}" writes their keys into Generated/Image`)
	end
	if #pendingTargets > 0 then
		print(`{#pendingTargets} of them sit where the Image input of "{CONFIG_PATH}" uploads from + have no upload in`)
		print(`"{LOCK_PATH}", a locked sync fails until they do. the upload is never run from here:`)
		print(`  {UPLOAD_COMMAND}`)
		print(`then commit the new files + "{LOCK_PATH}" together`)
	end
end
-- Class
local command, batchName, stagingDir, isDryRun = parseArgs(process.args)
local batches = getBatches(readRows())
if command == "list" then
	list(batches, stagingDir)
else
	local batch: Batch? = nil
	local names: { string } = {}
	for _, other in batches do
		table.insert(names, other.name)
		if other.name == batchName then
			batch = other
		end
	end
	assert(batch, `No batch named "{batchName}", there is: {table.concat(names, ", ")}`)
	assert(fs.isDir(stagingDir), `No staging folder at "{stagingDir}"\n{USAGE}`)
	land(batch, stagingDir, isDryRun)
end
process.exit(0)
