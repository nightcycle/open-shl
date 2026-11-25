--!strict
-- takes a map (or the scenes of a game) out of a legacy place file the way its export config says: what goes into
-- which file, without a script in any of them, and marked on the way out with the tags + attributes the services find
-- their parts by. the place has none of those + is never edited, so every mark is a rule of the config that's applied
-- again by each export
-- Services
local fs = require("@lune/fs")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
-- Packages
-- Modules
local Place = require("../modules/place")
-- Types
type AttributeValue = string | number | boolean
type Where = {
	class: string?,
	is_a: string?,
	has_child: string?,
}
-- what's said about every instance a path finds. a name of the path stands for each sibling of that name, "*" for
-- every child, "**" for everything below + "Name#2" for the second of the siblings named that. a rule that says
-- nothing else only keeps count
type Rule = {
	at: string,
	count: number, -- how many the path has to find, a place that changed stops the export instead of losing a mark
	where: Where?,
	drop_tags: { string }?,
	-- each is put into a new model of that name, whatever else the rule says is said about the model. siblings that
	-- are wrapped under one name share the model
	wrap: string?,
	value_attributes: string?, -- the child whose values turn into attributes, it's left behind afterwards
	name_attribute: string?, -- the attribute that's handed the name of the instance
	-- attributes that tell what's found apart: each is handed its prefix + the place of the instance among them
	numbered_attributes: { [string]: string }?,
	attributes: { [string]: AttributeValue }?,
	tags: { string }?,
	persistent: boolean?, -- sent to every client whatever it stands next to, a folder becomes a model to carry it
	-- the address an image or a mesh is loaded from, by the name of the property it's kept in. this, the move + the
	-- turn are about what the path found itself, wrapped or not
	contents: { [string]: string }?,
	-- the contents that are loaded from the upload of the file the repo holds of them, by the name of the property.
	-- the id table says which file a legacy id became + the lock of asphalt what that file went up as. one that has no
	-- upload yet stays as the place has it, one whose upload was refused shows nothing
	repoint: { string }?,
	move: { number }?, -- how far a part is shifted from where the place has it, in studs along the axes of the world
	turn: { number }?, -- how far it's turned on the spot it has, in degrees around the axes of the world
	-- a part that's only there to say where something is: nothing runs into it, touches it or is clicked on through it
	untouchable: boolean?,
}
type AddedPart = {
	name: string,
	-- a box is a Part unless it says what else, a SpawnLocation is the one part the engine stands an avatar on
	class: string?,
	min: { number },
	max: { number },
	tags: { string }?,
	attributes: { [string]: AttributeValue }?,
}
-- a model the place never had: boxes that can't be seen or touched, there to say where something is
type Add = {
	to: string,
	name: string,
	persistent: boolean?,
	parts: { AddedPart },
}
type Export = {
	from: string,
	-- an .rbxm takes the instance whole, a directory takes a file per child of it. a list of them writes the same
	-- piece once for each, rojo names what a file holds after the file
	to: string | { string },
	split: { string }?, -- the children that are a directory of their own, with a file per child
}
type Config = {
	place: string,
	known_scripts: string,
	exports: { Export },
	adds: { Add }?,
	rules: { Rule }?,
}
type Output = { path: string, inst: roblox.Instance }
-- the models that rules wrapped something into, by what they were put under + their name
type Wrappers = { [roblox.Instance]: { [string]: roblox.Instance } }
type Options = {
	configPath: string,
	reportPath: string?,
	-- everything is written below this directory instead, to hold an export against the files that are tracked
	outDir: string?,
	-- the lock + the id table a repoint goes by, the ones of the repo unless a trial of it brings its own
	lockPath: string,
	idsPath: string,
	isDryRun: boolean,
}
-- what the id table says became of a legacy upload: the file the repo holds of it, or why it holds none
type LegacyRow = { target: string, note: string }
-- the rows of the id table by legacy id + what asphalt uploaded a file as, by the blake3 of the file
type Uploads = {
	rows: { [string]: LegacyRow },
	lockedIds: { [string]: string },
}
-- what became of every content a repoint looked at
type Repoints = {
	repointedCount: number,
	legacyCount: number,
	otherCount: number,
	-- the ones the table lists a file for that isn't there: a batch that was meant to be landed
	missing: { string },
	blanks: { string },
}
-- Constants
local USAGE = "Usage: lune run scripts/util/export-map.lune.luau <map.export.yml> [--report <stripped.tsv>] "
	.. "[--out <directory>] [--lock <asphalt.lock.toml>] [--ids <legacy-ids.tsv>] [--dry-run]"
local WILDCARD = "*"
local DEEP_WILDCARD = "**"
-- a key that's spelled wrong would be a config that quietly does less than it says
local CONFIG_KEYS = { "place", "known_scripts", "exports", "adds", "rules" }
local EXPORT_KEYS = { "from", "to", "split" }
local ADD_KEYS = { "to", "name", "persistent", "parts" }
local ADDED_PART_KEYS = { "name", "class", "min", "max", "tags", "attributes" }
local RULE_KEYS = {
	"at",
	"count",
	"where",
	"drop_tags",
	"wrap",
	"value_attributes",
	"name_attribute",
	"numbered_attributes",
	"attributes",
	"tags",
	"persistent",
	"contents",
	"repoint",
	"move",
	"turn",
	"untouchable",
}
local WHERE_KEYS = { "class", "is_a", "has_child" }
local DEFAULT_ADDED_CLASS = "Part"
-- the flags that are followed by a path of their own
local VALUE_FLAGS = { "--report", "--out", "--lock", "--ids" }
local DEFAULT_LOCK_PATH = "asphalt.lock.toml"
local DEFAULT_IDS_PATH = "asset/legacy-ids.tsv"
local IDS_HEADER = "id\tgames\ttype\ttarget\tsha256\tbatch\tnote"
local COLUMN_DELIMITER = "\t"
-- what the id table has for a target of an upload the repo holds no file of + how its note starts when the upload
-- was turned down
local DROPPED_TARGET = "dropped"
local REFUSED_PREFIX = "refused:"
-- the ways a place spells the address of an upload
local ASSET_ID_PATTERNS = { "^rbxassetid://(%d+)$", "^https?://www%.roblox%.com/asset/?%?id=(%d+)$" }
local Instance = roblox.Instance
local Vector3 = (roblox :: any).Vector3
local CFrame = (roblox :: any).CFrame
local Content = (roblox :: any).Content
local Enum = (roblox :: any).Enum
-- Variables
-- References
-- Private Functions
local function parseArgs(args: { string }): Options
	local configPath: string? = nil
	local values: { [string]: string } = {}
	local isDryRun = false
	local valueFlag: string? = nil
	for _, arg in args do
		if valueFlag then
			values[valueFlag] = (arg:gsub("\\", "/"))
			valueFlag = nil
		elseif table.find(VALUE_FLAGS, arg) then
			valueFlag = arg
		elseif arg == "--dry-run" then
			isDryRun = true
		else
			assert(arg:sub(1, 1) ~= "-", `Unknown flag: {arg}\n{USAGE}`)
			assert(configPath == nil, `Expected one export config\n{USAGE}`)
			configPath = (arg:gsub("\\", "/"))
		end
	end
	assert(valueFlag == nil, `Expected a path after {valueFlag}\n{USAGE}`)
	return {
		configPath = assert(configPath, USAGE),
		reportPath = values["--report"],
		outDir = values["--out"],
		lockPath = values["--lock"] or DEFAULT_LOCK_PATH,
		idsPath = values["--ids"] or DEFAULT_IDS_PATH,
		isDryRun = isDryRun,
	}
end

local function assertKeys(value: unknown, keys: { string }, at: string)
	assert(type(value) == "table", `{at} isn't a table`)
	for key in value :: { [unknown]: unknown } do
		assert(
			type(key) == "string" and table.find(keys, key) ~= nil,
			`{at} has a "{tostring(key)}", which isn't something it can say`
		)
	end
end

local function getIfStringList(value: unknown): boolean
	if type(value) ~= "table" then
		return false
	end
	for _, item in value :: { unknown } do
		if type(item) ~= "string" then
			return false
		end
	end
	return true
end

local function getIfAttributes(value: unknown): boolean
	if type(value) ~= "table" then
		return false
	end
	for key, item in value :: { [unknown]: unknown } do
		if type(key) ~= "string" or (type(item) ~= "string" and type(item) ~= "number" and type(item) ~= "boolean") then
			return false
		end
	end
	return true
end

local function getIfContents(value: unknown): boolean
	if type(value) ~= "table" then
		return false
	end
	for key, item in value :: { [unknown]: unknown } do
		if type(key) ~= "string" or type(item) ~= "string" then
			return false
		end
	end
	return true
end

local function getIfOffset(value: unknown): boolean
	if type(value) ~= "table" or #(value :: { unknown }) ~= 3 then
		return false
	end
	for _, item in value :: { unknown } do
		if type(item) ~= "number" then
			return false
		end
	end
	return true
end

-- where an export lands, most of them in one place
local function getDestinations(export: Export): { string }
	local to = export.to
	return if type(to) == "string" then { to } else to
end

local function getIfBox(part: AddedPart): boolean
	if type(part.min) ~= "table" or type(part.max) ~= "table" or #part.min ~= 3 or #part.max ~= 3 then
		return false
	end
	for axis = 1, 3 do
		if type(part.min[axis]) ~= "number" or type(part.max[axis]) ~= "number" or part.min[axis] >= part.max[axis] then
			return false
		end
	end
	return true
end

-- lune knows the classes of the engine, one it has never heard of can't be made
local function getIfPartClass(className: unknown): boolean
	if type(className) ~= "string" then
		return false
	end
	local isMade, inst = pcall(Instance.new, className)
	return isMade and inst:IsA("BasePart")
end

local function readConfig(path: string): Config
	assert(fs.isFile(path), `no export config at "{path}"`)
	local config = serde.decode("yaml", fs.readFile(path))
	assertKeys(config, CONFIG_KEYS, `"{path}"`)
	assert(type(config.place) == "string", `"{path}" needs a place`)
	assert(type(config.known_scripts) == "string", `"{path}" needs its known_scripts`)
	assert(type(config.exports) == "table" and #config.exports > 0, `"{path}" has no exports`)
	for index, export: Export in config.exports do
		local at = `export {index} of "{path}"`
		assertKeys(export, EXPORT_KEYS, at)
		assert(
			type(export.from) == "string"
				and (type(export.to) == "string" or (getIfStringList(export.to) and #getDestinations(export) > 0)),
			`{at} needs a from and a to`
		)
		assert(export.split == nil or getIfStringList(export.split), `{at} has a split that isn't a list of names`)
	end
	for index, add: Add in config.adds or {} do
		local at = `add {index} of "{path}"`
		assertKeys(add, ADD_KEYS, at)
		assert(type(add.to) == "string" and type(add.name) == "string", `{at} needs a to and a name`)
		assert(type(add.parts) == "table" and #add.parts > 0, `{at} has no parts`)
		for _, part in add.parts do
			assertKeys(part, ADDED_PART_KEYS, `a part of {at}`)
			assert(type(part.name) == "string" and getIfBox(part), `{at} has a part without a name, a min and a max`)
			assert(part.class == nil or getIfPartClass(part.class), `{at} has a part of a class that isn't a part`)
			assert(part.tags == nil or getIfStringList(part.tags), `{at} has tags that aren't a list of names`)
			assert(part.attributes == nil or getIfAttributes(part.attributes), `{at} has attributes of another kind`)
		end
	end
	for index, rule: Rule in config.rules or {} do
		local at = `rule {index} of "{path}"`
		assertKeys(rule, RULE_KEYS, at)
		assert(type(rule.at) == "string", `{at} needs a path to be at`)
		assert(type(rule.count) == "number", `{at} ("{rule.at}") needs the count of what it finds`)
		if rule.where ~= nil then
			assertKeys(rule.where, WHERE_KEYS, `the where of {at}`)
		end
		assert(rule.drop_tags == nil or getIfStringList(rule.drop_tags), `{at} has drop_tags that aren't names`)
		assert(rule.tags == nil or getIfStringList(rule.tags), `{at} has tags that aren't a list of names`)
		assert(rule.attributes == nil or getIfAttributes(rule.attributes), `{at} has attributes of another kind`)
		assert(
			rule.numbered_attributes == nil or getIfAttributes(rule.numbered_attributes),
			`{at} has numbered_attributes that aren't prefixes`
		)
		assert(rule.wrap == nil or type(rule.wrap) == "string", `{at} has a wrap that isn't a name`)
		assert(rule.value_attributes == nil or type(rule.value_attributes) == "string", `{at}: value_attributes`)
		assert(rule.name_attribute == nil or type(rule.name_attribute) == "string", `{at}: name_attribute`)
		assert(rule.persistent == nil or type(rule.persistent) == "boolean", `{at}: persistent`)
		assert(rule.contents == nil or getIfContents(rule.contents), `{at} has contents that aren't addresses`)
		assert(rule.repoint == nil or getIfStringList(rule.repoint), `{at} has a repoint that isn't a list of names`)
		assert(rule.move == nil or getIfOffset(rule.move), `{at} has a move that isn't 3 numbers`)
		assert(rule.turn == nil or getIfOffset(rule.turn), `{at} has a turn that isn't 3 numbers`)
		assert(rule.untouchable == nil or type(rule.untouchable) == "boolean", `{at}: untouchable`)
	end
	return config
end

local function getIfMatch(inst: roblox.Instance, where: Where?): boolean
	if where == nil then
		return true
	end
	if where.class and inst.ClassName ~= where.class then
		return false
	end
	if where.is_a and not inst:IsA(where.is_a) then
		return false
	end
	if where.has_child and inst:FindFirstChild(where.has_child) == nil then
		return false
	end
	return true
end

local function find(place: roblox.DataModel, rule: Rule): { roblox.Instance }
	local found: { roblox.Instance } = { place }
	for _, segment in Place.parsePath(rule.at) do
		local nextFound: { roblox.Instance } = {}
		for _, parent in found do
			local named: { roblox.Instance }
			if segment.name == DEEP_WILDCARD then
				named = parent:GetDescendants()
			elseif segment.name == WILDCARD then
				named = parent:GetChildren()
			else
				named = Place.getNamed(parent, segment.name)
			end
			if segment.index then
				table.insert(nextFound, named[segment.index])
			else
				table.move(named, 1, #named, #nextFound + 1, nextFound)
			end
		end
		found = nextFound
	end
	local out: { roblox.Instance } = {}
	for _, inst in found do
		if getIfMatch(inst, rule.where) then
			table.insert(out, inst)
		end
	end
	return out
end

local function setAttributes(inst: roblox.Instance, attributes: { [string]: AttributeValue }?)
	if attributes then
		for name, value in attributes do
			inst:SetAttribute(name, value)
		end
	end
end

local function addTags(inst: roblox.Instance, tags: { string }?)
	if tags then
		for _, tag in tags do
			inst:AddTag(tag)
		end
	end
end

local function setPersistent(model: roblox.Instance)
	(model :: any).ModelStreamingMode = Enum.ModelStreamingMode.Persistent
end

-- a folder has no streaming mode, a model that holds the same + answers to the same name does
local function newModelOf(folder: roblox.Instance): roblox.Instance
	local model = Instance.new("Model")
	model.Name = folder.Name
	addTags(model, folder:GetTags())
	for name, value in folder:GetAttributes() do
		model:SetAttribute(name, value)
	end
	for _, child in folder:GetChildren() do
		child.Parent = model
	end
	model.Parent = folder.Parent
	folder:Destroy()
	return model
end

-- returns what the rule ended up being about, which isn't what its path found once that was wrapped or swapped
local function apply(rule: Rule, inst: roblox.Instance, order: number, wrappers: Wrappers): roblox.Instance
	local dropTags: { string } = rule.drop_tags or {}
	for _, tag in dropTags do
		assert(inst:HasTag(tag), `"{rule.at}" drops a tag "{tag}" that "{inst.Name}" doesn't have`)
		inst:RemoveTag(tag)
	end
	local contents: { [string]: string } = rule.contents or {}
	for name, uri in contents do
		local isSet = pcall(function()
			(inst :: any)[name] = Content.fromUri(uri)
		end)
		assert(isSet, `"{rule.at}": a {inst.ClassName} has no content named "{name}"`)
	end
	local move = rule.move
	if move then
		assert(inst:IsA("BasePart"), `"{rule.at}": only a part is moved, "{inst.Name}" is a {inst.ClassName}`)
		local properties = inst :: any
		properties.CFrame += Vector3.new(move[1], move[2], move[3])
	end
	local turn = rule.turn
	if turn then
		assert(inst:IsA("BasePart"), `"{rule.at}": only a part is turned, "{inst.Name}" is a {inst.ClassName}`)
		local properties = inst :: any
		local position = properties.CFrame.Position
		local rotation = CFrame.Angles(math.rad(turn[1]), math.rad(turn[2]), math.rad(turn[3]))
		properties.CFrame = CFrame.new(position) * rotation * (properties.CFrame - position)
	end
	if rule.untouchable then
		assert(inst:IsA("BasePart"), `"{rule.at}": only a part is untouchable, "{inst.Name}" is a {inst.ClassName}`)
		local properties = inst :: any
		properties.CanCollide = false
		properties.CanTouch = false
		properties.CanQuery = false
	end
	local target = inst
	if rule.wrap then
		local parent = assert(inst.Parent, `"{rule.at}": "{inst.Name}" has nothing to be wrapped under`)
		local siblings = wrappers[parent] or {}
		wrappers[parent] = siblings
		local wrapper = siblings[rule.wrap]
		if not wrapper then
			wrapper = Instance.new("Model")
			wrapper.Name = rule.wrap
			wrapper.Parent = parent
			siblings[rule.wrap] = wrapper
		end
		inst.Parent = wrapper
		target = wrapper
	end
	if rule.value_attributes then
		local values = assert(
			inst:FindFirstChild(rule.value_attributes),
			`"{rule.at}": "{inst.Name}" has no "{rule.value_attributes}"`
		)
		for _, value in values:GetChildren() do
			assert(value:IsA("ValueBase") and #value:GetChildren() == 0, `"{rule.at}": "{value.Name}" isn't a value`)
			target:SetAttribute(value.Name, (value :: any).Value)
		end
		values:Destroy()
	end
	if rule.name_attribute then
		target:SetAttribute(rule.name_attribute, inst.Name)
	end
	local numberedAttributes: { [string]: string } = rule.numbered_attributes or {}
	for name, prefix in numberedAttributes do
		target:SetAttribute(name, `{prefix}{order}`)
	end
	setAttributes(target, rule.attributes)
	addTags(target, rule.tags)
	if rule.persistent then
		if target.ClassName == "Folder" then
			target = newModelOf(target)
		end
		assert(target:IsA("Model"), `"{rule.at}": only a model or a folder is persistent, wrap "{target.Name}" first`)
		setPersistent(target)
	end
	return target
end

-- the upload an address names, nil for a file of the engine's own + for nothing at all
local function getAssetId(uri: string?): string?
	local text = (uri or ""):lower():match("^%s*(.-)%s*$") or ""
	for _, pattern in ASSET_ID_PATTERNS do
		local id = text:match(pattern)
		if id then
			return id
		end
	end
	return nil
end

local function readUploads(options: Options): Uploads
	local idsPath = options.idsPath
	assert(fs.isFile(idsPath), `no id table at "{idsPath}", is this the root of the repo?`)
	local lines = fs.readFile(idsPath):gsub("\r", ""):split("\n")
	assert(lines[1] == IDS_HEADER, `"{idsPath}" starts with a header this tool doesn't know`)
	local rows: { [string]: LegacyRow } = {}
	for index, line in lines do
		if index == 1 or line == "" then
			continue
		end
		local cells = line:split(COLUMN_DELIMITER)
		assert(#cells == 7, `line {index} of "{idsPath}" has {#cells} columns`)
		rows[cells[1]] = { target = cells[4], note = cells[7] }
	end
	-- asphalt keys an upload by the blake3 of the file it made it of
	assert(fs.isFile(options.lockPath), `no lock of asphalt at "{options.lockPath}"`)
	local lockedIds: { [string]: string } = {}
	local lock = serde.decode("toml", fs.readFile(options.lockPath))
	local inputs = if type(lock) == "table" then lock.inputs else nil
	local images = if type(inputs) == "table" then inputs.Image else nil
	if type(images) == "table" then
		for hash, entry in images do
			lockedIds[hash] = string.format("%d", entry.asset_id)
		end
	end
	return { rows = rows, lockedIds = lockedIds }
end

-- a content that isn't re-pointed is never written, so what an export holds of it is what the place does to the byte
local function repoint(rule: Rule, inst: roblox.Instance, path: string, uploads: Uploads, repoints: Repoints)
	local names: { string } = rule.repoint or {}
	for _, name in names do
		local properties = inst :: any
		local isRead, uri = pcall(function(): string?
			return properties[name].Uri
		end)
		assert(isRead, `"{rule.at}": a {inst.ClassName} has no content named "{name}"`)
		local id = getAssetId(uri)
		local row = if id then uploads.rows[id] else nil
		if row == nil then
			repoints.otherCount += 1
		elseif row.target == DROPPED_TARGET and row.note:sub(1, #REFUSED_PREFIX) == REFUSED_PREFIX then
			properties[name] = Content.fromUri("")
			table.insert(repoints.blanks, `{path}.{name}`)
		else
			local isLanded = fs.isFile(row.target)
			local lockedId = if isLanded then uploads.lockedIds[serde.hash("blake3", fs.readFile(row.target))] else nil
			if lockedId then
				properties[name] = Content.fromUri(`rbxassetid://{lockedId}`)
				repoints.repointedCount += 1
			else
				repoints.legacyCount += 1
				-- a target that's a path is a file the repo was going to hold
				if not isLanded and row.target:find(Place.PATH_DELIMITER, 1, true) then
					table.insert(repoints.missing, `{path}.{name} ("{row.target}")`)
				end
			end
		end
	end
end

local function printRepoints(repoints: Repoints)
	local count = repoints.repointedCount + repoints.legacyCount + repoints.otherCount + #repoints.blanks
	print(
		`{count} picture(s) looked at: {repoints.repointedCount} re-pointed, {repoints.legacyCount} still on their `
			.. `legacy upload ({#repoints.missing} of them listed with no file), {repoints.otherCount} not a legacy `
			.. `image, {#repoints.blanks} blank`
	)
	for _, missing in repoints.missing do
		print(`  listed, no file: {missing}`)
	end
	for _, blank in repoints.blanks do
		print(`  blank, its upload was refused: {blank}`)
	end
end

local function add(place: roblox.DataModel, added: Add)
	local parent = Place.findInstance(place, added.to)
	assert(parent:FindFirstChild(added.name) == nil, `"{added.to}" already has a "{added.name}"`)
	local model = Instance.new("Model")
	model.Name = added.name
	for _, box in added.parts do
		local min = Vector3.new(box.min[1], box.min[2], box.min[3])
		local max = Vector3.new(box.max[1], box.max[2], box.max[3])
		local part = Instance.new(box.class or DEFAULT_ADDED_CLASS)
		part.Name = box.name
		local properties = part :: any
		properties.Anchored = true
		properties.CanCollide = false
		properties.CanTouch = false
		properties.CanQuery = false
		properties.CastShadow = false
		-- a box around the whole city would be what every click in studio lands on
		properties.Locked = true
		properties.Transparency = 1
		properties.Size = max - min
		properties.CFrame = CFrame.new((min + max) / 2)
		setAttributes(part, box.attributes)
		addTags(part, box.tags)
		part.Parent = model
	end
	if added.persistent then
		setPersistent(model)
	end
	model.Parent = parent
end

-- the files of a directory are named after what they hold, so each name has to be one + none can be taken twice
local function getChildOutputs(dir: string, inst: roblox.Instance, split: { string }): { Output }
	local outputs: { Output } = {}
	local used: { [string]: boolean } = {}
	for _, child in inst:GetChildren() do
		local key = child.Name:lower()
		assert(Place.getIfFileName(child.Name), `"{child.Name}" of "{inst.Name}" can't be a file name`)
		assert(not used[key], `"{inst.Name}" has two children named "{child.Name}", it can't be a file per child`)
		used[key] = true
		if table.find(split, child.Name) then
			-- a directory is a plain folder to rojo, anything more would be lost on the way
			assert(
				child.ClassName == "Folder" and #child:GetTags() == 0 and next(child:GetAttributes()) == nil,
				`"{child.Name}" isn't a plain folder, it can't be split into a directory`
			)
			for _, output in getChildOutputs(`{dir}/{child.Name}`, child, {}) do
				table.insert(outputs, output)
			end
		else
			table.insert(outputs, { path = `{dir}/{child.Name}.rbxm`, inst = child })
		end
	end
	for _, name in split do
		assert(used[name:lower()], `"{inst.Name}" has no "{name}" to split`)
	end
	return outputs
end

local function getDir(path: string): string
	local dir = path:match("^(.*)/[^/]+$")
	return if dir == "" then "/" else dir or "."
end

local function writeDirs(path: string)
	if fs.isDir(path) then
		return
	end
	local parent = getDir(path)
	if parent ~= path and parent ~= "." and parent ~= "/" then
		writeDirs(parent)
	end
	fs.writeDir(path)
end
-- Class
do
	local options = parseArgs(process.args)
	local config = readConfig(options.configPath)
	assert(fs.isFile(config.place), `No place file found at "{config.place}"`)
	local place = roblox.deserializePlace(fs.readFile(config.place))
	local known = Place.readKnownScripts(config.known_scripts)

	local roots: { roblox.Instance } = {}
	local sourceCount = 0
	for _, export in config.exports do
		local root = Place.findInstance(place, export.from)
		local refusal = Place.getRefusal(place, root)
		assert(refusal == nil, `"{export.from}" isn't exported: {refusal}`)
		for _, other in roots do
			assert(
				root ~= other and not root:IsDescendantOf(other) and not other:IsDescendantOf(root),
				`"{export.from}" is exported twice`
			)
		end
		table.insert(roots, root)
		sourceCount += #root:GetDescendants() + 1
	end
	print(`{sourceCount} instance(s) in what "{config.place}" has at the exported paths`)

	-- every rule is looked up before any of them changes a thing, so a path always means what it does in the place
	local rules: { Rule } = config.rules or {}
	local found: { { roblox.Instance } } = {}
	for index, rule in rules do
		found[index] = find(place, rule)
		assert(
			#found[index] == rule.count,
			`"{rule.at}" finds {#found[index]} instance(s) in "{config.place}", the rule expects {rule.count}`
		)
		for _, inst in found[index] do
			local isExported = false
			for _, root in roots do
				isExported = isExported or inst == root or inst:IsDescendantOf(root)
			end
			assert(isExported, `"{rule.at}" is about "{inst.Name}", which no export takes along`)
		end
	end
	-- an instance that a rule replaced is what the ones after it are about
	local replaced: { [roblox.Instance]: roblox.Instance } = {}
	local wrappers: Wrappers = {}
	-- the tables of the uploads are only read for a config that goes by them
	local hasRepoint = false
	for _, rule in rules do
		hasRepoint = hasRepoint or rule.repoint ~= nil
	end
	local uploads: Uploads = if hasRepoint then readUploads(options) else { rows = {}, lockedIds = {} }
	local repoints: Repoints = { repointedCount = 0, legacyCount = 0, otherCount = 0, missing = {}, blanks = {} }
	for index, rule in rules do
		for order, inst in found[index] do
			local current = replaced[inst] or inst
			if rule.repoint then
				repoint(rule, current, Place.getPath(place, current), uploads, repoints)
			end
			local target = apply(rule, current, order, wrappers)
			if not rule.wrap and target ~= current then
				replaced[inst] = target
				local rootIndex = table.find(roots, current)
				if rootIndex then
					roots[rootIndex] = target
				end
			end
		end
		print(`{#found[index]} x "{rule.at}"`)
	end
	if hasRepoint then
		printRepoints(repoints)
	end
	local adds: { Add } = config.adds or {}
	for _, added in adds do
		add(place, added)
		print(`added "{added.to}/{added.name}"`)
	end

	local stripped: { Place.StrippedScript } = {}
	for index, root in roots do
		for _, strippedScript in Place.stripScripts(root, known) do
			strippedScript.path = `{config.exports[index].from}/{strippedScript.path}`
			table.insert(stripped, strippedScript)
		end
	end
	print(`{#stripped} script(s) stripped, each of them is on "{config.known_scripts}"`)

	local outputs: { Output } = {}
	local destinations: { string } = {}
	local expectedCount = 0
	local directoryCount = 0
	local outDir = options.outDir
	for index, export in config.exports do
		local root = roots[index]
		for _, to in getDestinations(export) do
			local destination = if outDir then `{outDir}/{to}` else to
			table.insert(destinations, destination)
			if destination:lower():match("%.rbxm$") then
				assert(export.split == nil, `"{to}" is one file, there's nothing to split`)
				table.insert(outputs, { path = destination, inst = root })
			else
				local split = export.split or {}
				local childOutputs = getChildOutputs(destination, root, split)
				assert(#childOutputs > 0, `"{export.from}" has no children to export`)
				table.move(childOutputs, 1, #childOutputs, #outputs + 1, outputs)
				-- the instance itself + each child that's split are directories, not something a file holds
				directoryCount += 1 + #split
			end
			expectedCount += #root:GetDescendants() + 1
		end
	end
	print(`{expectedCount} instance(s) once the rules are applied + the scripts are gone`)

	-- reject collisions before touching the disk
	local planned: { [string]: boolean } = {}
	for _, destination in destinations do
		assert(not fs.isFile(destination) and not fs.isDir(destination), `Output already exists: {destination}`)
	end
	for _, output in outputs do
		assert(not planned[output.path:lower()], `Conflicting output path: {output.path}`)
		planned[output.path:lower()] = true
	end
	if options.isDryRun then
		print(`dry run: {#outputs} file(s) would be written`)
		return
	end
	local writtenCount = 0
	local unionCount = 0
	for _, output in outputs do
		writeDirs(getDir(output.path))
		local contents, rewrittenCount = Place.serialize(output.inst)
		unionCount += rewrittenCount
		fs.writeFile(output.path, contents)
		-- what was written is read back, a script that's still in there is never left for a build to pick up
		writtenCount += Place.countWritten(output.path)
	end
	assert(
		writtenCount + directoryCount == expectedCount,
		`{writtenCount} instance(s) in the files + {directoryCount} directories, {expectedCount} were expected`
	)
	print(`wrote {#outputs} file(s) holding {writtenCount} instance(s), {directoryCount} more are directories`)
	if unionCount > 0 then
		print(`{unionCount} union(s) name their asset in AssetId now, the way the rest of lib does`)
	end
	local reportPath = options.reportPath
	if reportPath then
		fs.writeFile(reportPath, Place.getStrippedReport(stripped))
		print(`wrote "{reportPath}"`)
	end
	print("export complete")
end
