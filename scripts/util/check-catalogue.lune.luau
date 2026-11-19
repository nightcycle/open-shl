--!strict
-- reads the item library of a built place the way the game will: every template has to be something
-- Definition/Appearance/Item can describe + Util/Appearance/Item can put on a rig. with the catalogue tables of a game
-- it also checks that every id + every image they name is there. a place that isn't handed any is held to the tables
-- of the game it was built for, if that game has them. nothing is run, a template that passes can still look wrong
-- Services
local fs = require("@lune/fs")
local luau = require("@lune/luau")
local process = require("@lune/process")
local roblox = require("@lune/roblox")
local serde = require("@lune/serde")
-- Packages
-- Modules
local game = require("../modules/game")
-- Types
type EntryRow = { LegacyCategory: string, LegacyName: string, ItemIds: { string } }
type FaceRow = { Id: string, Image: string }
type PatternRow = { Key: string, Image: string }
-- Generated/Image as the build has it: a folder of asset/image is a table, a file is the address it's loaded from
type Images = { [string]: string | Images }
type Summary = {
	failures: { string },
	itemCounts: { [string]: number },
	-- what an item brings along for another item to sit on, by the name of the attachment
	mountCounts: { [string]: number },
	-- the items that sit on one of those instead of on the rig
	mounted: { [string]: { string } },
	meshIds: { [string]: boolean },
	textureGroupCounts: { [string]: number },
	ids: { [string]: boolean },
}
-- Constants
local USAGE = "Usage: lune run scripts/util/check-catalogue.lune.luau <place.rbxl> [data/shl-<n>/catalogue]"
local LIBRARY_PATH = "ReplicatedStorage/lib/character"
local BUILD_CONFIG_PATH = "ReplicatedStorage/Generated/BUILD_CONFIG"
local GAME_PATTERN = '%f[%w_]GAME%s*=%s*"([^"]*)"'
local IMAGE_MODULE_PATH = "ReplicatedStorage/Generated/Image"
local IMAGE_ROOT = "asset/image/"
local PATH_DELIMITER = "/"
local ID_DELIMITER = "_"
local ROOT_NAME = "root"
local TEXTURE_GROUP_ATTRIBUTE = "TextureGroup"
-- the closed sets of Type/Character/Identity/Appearance
local ITEM_GROUPS = { "clothing", "costume", "cosmetics", "body" }
local TEXTURE_GROUP_KEYS = { "Primary", "Secondary", "Tertiary", "Hair", "Skin" }
local ITEM_TAGS = { "IsMask", "Hood", "Mask", "MouthCover", "Hair" }
-- pseudo-enum.toml
local RARITIES = { "VeryCommon", "Common", "Uncommon", "Rare", "Legendary" }
-- a face item is an image, a template filed under one of these could never be reached by its id. the slots are a
-- game's own: SHL2 draws eyebrows, eyes + a mouth, SHL3 eyes + a mouth, SHL1 the whole face as one picture
local FACE_GROUP = "cosmetics"
local FACE_CATEGORIES = { "eyebrows", "eyes", "mouth", "face" }
-- what an item can name as its anchor on an R15 rig
local RIG_PART_NAMES = {
	"Head",
	"UpperTorso",
	"LowerTorso",
	"LeftUpperArm",
	"LeftLowerArm",
	"LeftHand",
	"RightUpperArm",
	"RightLowerArm",
	"RightHand",
	"LeftUpperLeg",
	"LeftLowerLeg",
	"LeftFoot",
	"RightUpperLeg",
	"RightLowerLeg",
	"RightFoot",
	"HumanoidRootPart",
}
-- Variables
-- References
-- Private Functions
local function parseArgs(args: { string }): (string, string?)
	assert(#args >= 1 and #args <= 2, `Expected a place and at most a catalogue folder\n{USAGE}`)
	return (args[1]:gsub("\\", "/")), if args[2] then (args[2]:gsub("\\", "/")) else nil
end

local function read(inst: roblox.Instance, name: string): any
	-- lune's Instance typedef leaves out dynamic property indexing
	return (inst :: any)[name]
end

local function findInstance(place: roblox.DataModel, instPath: string): roblox.Instance
	local inst: roblox.Instance? = nil
	for _, name in instPath:split(PATH_DELIMITER) do
		local parent: roblox.Instance = inst or place
		inst = assert(parent:FindFirstChild(name), `No instance at "{name}" in "{instPath}"`)
	end
	return assert(inst, `Expected an instance path, received "{instPath}"`)
end

-- where the tables of the game a place was built for are kept, nil for a game that has none
local function getCataloguePath(place: roblox.DataModel): string?
	local gameId = (read(findInstance(place, BUILD_CONFIG_PATH), "Source") :: string):match(GAME_PATTERN)
	assert(type(gameId) == "string", `"{BUILD_CONFIG_PATH}" doesn't say which game this is`)
	local path = `{game.CONTENTS[game.getId(gameId)].DataPath}/catalogue`
	return if fs.isDir(path) then path else nil
end

-- the module is a table of strings + nothing else, it's read by running it
local function readImages(place: roblox.DataModel): Images
	local source: string = read(findInstance(place, IMAGE_MODULE_PATH), "Source")
	local images = luau.load(source, { debugName = IMAGE_MODULE_PATH })()
	assert(type(images) == "table", `"{IMAGE_MODULE_PATH}" doesn't return its images`)
	return images
end

-- a row names its image by the file under asset/image, the build has it under the same path
local function getIfImage(images: Images, path: string): boolean
	if path:sub(1, #IMAGE_ROOT) ~= IMAGE_ROOT then
		return false
	end
	local current: string | Images = images
	for _, key in path:sub(#IMAGE_ROOT + 1):split(PATH_DELIMITER) do
		if type(current) ~= "table" then
			return false
		end
		current = current[key]
	end
	return type(current) == "string"
end

local function getDescendantsOfClass(inst: roblox.Instance, className: string): { roblox.Instance }
	local out: { roblox.Instance } = {}
	for _, desc in inst:GetDescendants() do
		if desc:IsA(className) then
			table.insert(out, desc)
		end
	end
	return out
end

local function getAssetId(content: any): string?
	if content == nil or content.SourceType.Name ~= "Uri" then
		return nil
	end
	return (content.Uri :: string):match("(%d+)%s*$")
end

-- a single piece: what holds the one attachment that names where it's worn
local function checkPiece(summary: Summary, id: string, piece: roblox.Instance): string?
	local root: roblox.Instance? = if piece.ClassName == "Model" then piece:FindFirstChild(ROOT_NAME) else piece
	if not root then
		return `couldn't find {ROOT_NAME}`
	end
	if not root:IsA("BasePart") then
		return `{ROOT_NAME} wasn't BasePart`
	end
	local attachments = getDescendantsOfClass(root, "Attachment")
	if #attachments ~= 1 then
		return `{#attachments} attachments under the part that anchors it, expected only one`
	end
	local anchorName = attachments[1].Name
	if table.find(RIG_PART_NAMES, anchorName) == nil then
		local mounted = summary.mounted[anchorName] or {}
		table.insert(mounted, id)
		summary.mounted[anchorName] = mounted
	end
	-- an attachment anywhere else in the piece is there for another item
	for _, attachment in getDescendantsOfClass(piece, "Attachment") do
		if attachment ~= attachments[1] then
			summary.mountCounts[attachment.Name] = (summary.mountCounts[attachment.Name] or 0) + 1
		end
	end
	return nil
end

local function checkItem(summary: Summary, group: string, category: string, item: roblox.Instance)
	local id = table.concat({ group, category, item.Name }, ID_DELIMITER)
	local function fail(reason: string)
		table.insert(summary.failures, `{group}/{category}/{item.Name}: {reason}`)
	end
	local libraryCategory = `{group}/{category}`
	summary.itemCounts[libraryCategory] = (summary.itemCounts[libraryCategory] or 0) + 1
	if summary.ids[id] then
		fail("two items of the category have that name, only one of them can be reached")
	end
	summary.ids[id] = true

	-- Definition/Appearance/Item.getIndex
	if #id:split(ID_DELIMITER) ~= 3 then
		fail(`"{id}" doesn't split into 3 keys`)
	end
	if item.Name == "" or item.Name:find(PATH_DELIMITER, 1, true) then
		fail("bad key")
	end
	-- Definition/Appearance/Item.get
	local name = item:GetAttribute("Name")
	if name ~= nil and type(name) ~= "string" then
		fail("Name isn't a string")
	end
	local rarity = item:GetAttribute("Rarity")
	if rarity ~= nil and (type(rarity) ~= "string" or table.find(RARITIES, rarity) == nil) then
		fail(`Rarity "{tostring(rarity)}" isn't one`)
	end
	for _, tag in item:GetTags() do
		if table.find(ITEM_TAGS, tag) == nil then
			fail(`tag "{tag}" fails the definition, the item would be skipped`)
		end
	end
	local instances = item:GetDescendants()
	table.insert(instances, 1, item)
	for _, inst in instances do
		if inst:IsA("BasePart") then
			local textureGroup = inst:GetAttribute(TEXTURE_GROUP_ATTRIBUTE)
			if textureGroup ~= nil then
				if type(textureGroup) ~= "string" or table.find(TEXTURE_GROUP_KEYS, textureGroup) == nil then
					fail(`"{inst.Name}" has texture group "{tostring(textureGroup)}", which nothing would color`)
				else
					summary.textureGroupCounts[textureGroup] = (summary.textureGroupCounts[textureGroup] or 0) + 1
				end
			end
		end
		if inst.ClassName == "MeshPart" then
			local meshId = getAssetId(read(inst, "MeshContent"))
			if meshId == nil then
				fail(`"{inst.Name}" is a MeshPart without a mesh`)
			else
				summary.meshIds[meshId] = true
			end
		elseif inst.ClassName == "SpecialMesh" then
			local meshId = getAssetId(read(inst, "MeshContent"))
			if meshId then
				summary.meshIds[meshId] = true
			end
		elseif inst:IsA("LuaSourceContainer") then
			fail(`holds the script "{inst.Name}"`)
		end
	end

	-- Util/Appearance/Item.apply
	if item:IsA("BasePart") or item.ClassName == "Model" then
		local reason = checkPiece(summary, id, item)
		if reason then
			fail(reason)
		end
	elseif item.ClassName == "Folder" then
		local pieceCount = 0
		for _, piece in item:GetChildren() do
			if piece:IsA("BasePart") or piece.ClassName == "Model" then
				pieceCount += 1
				local reason = checkPiece(summary, id, piece)
				if reason then
					fail(`piece "{piece.Name}": {reason}`)
				end
			end
		end
		if pieceCount == 0 then
			fail("a folder without a piece to wear")
		end
	else
		fail(`a "{item.ClassName}" can't be worn`)
	end
end

local function readJson(path: string): any
	assert(fs.isFile(path), `No file found at "{path}"`)
	return serde.decode("json", fs.readFile(path))
end

-- every id a table of the game names has to be an item of this build + every image one of its images
local function checkCatalogue(summary: Summary, cataloguePath: string, images: Images)
	local entryData = readJson(`{cataloguePath}/entry.json`)
	local faces: { FaceRow } = readJson(`{cataloguePath}/face.json`)
	local patterns: { PatternRow } = readJson(`{cataloguePath}/pattern.json`)
	local faceIds: { [string]: boolean } = {}
	for _, face in faces do
		faceIds[face.Id] = true
		local keys = face.Id:split(ID_DELIMITER)
		if #keys ~= 3 or keys[1] ~= FACE_GROUP or table.find(FACE_CATEGORIES, keys[2]) == nil then
			table.insert(summary.failures, `face "{face.Id}" isn't filed under a face category`)
		end
		if not getIfImage(images, face.Image) then
			table.insert(summary.failures, `face "{face.Id}" names "{face.Image}", which isn't an image of the build`)
		end
	end
	for _, pattern in patterns do
		if not getIfImage(images, pattern.Image) then
			table.insert(
				summary.failures,
				`pattern "{pattern.Key}" names "{pattern.Image}", which isn't an image of the build`
			)
		end
	end
	local rows: { EntryRow } = {}
	for _, key in { "Entries", "Extras" } do
		for _, row in entryData[key] or {} do
			table.insert(rows, row)
		end
	end
	local idCount, faceCount = 0, 0
	for _, row in rows do
		if #row.ItemIds == 0 then
			table.insert(summary.failures, `entry "{row.LegacyCategory}/{row.LegacyName}" has no item`)
		end
		for _, id in row.ItemIds do
			idCount += 1
			if faceIds[id] then
				faceCount += 1
			elseif not summary.ids[id] then
				table.insert(
					summary.failures,
					`entry "{row.LegacyCategory}/{row.LegacyName}" names "{id}", which isn't in the library`
				)
			end
		end
	end
	print(`{#rows} entries name {idCount} ids: {idCount - faceCount} templates, {faceCount} faces`)
	print(`{#faces} faces + {#patterns} patterns name their image`)
end
-- Class
do
	local placePath, cataloguePath = parseArgs(process.args)
	assert(fs.isFile(placePath), `No place file found at "{placePath}"`)
	local place = roblox.deserializePlace(fs.readFile(placePath))
	local library = findInstance(place, LIBRARY_PATH)
	cataloguePath = cataloguePath or getCataloguePath(place)
	local summary: Summary = {
		failures = {},
		itemCounts = {},
		mountCounts = {},
		mounted = {},
		meshIds = {},
		textureGroupCounts = {},
		ids = {},
	}
	for _, groupFolder in library:GetChildren() do
		if table.find(ITEM_GROUPS, groupFolder.Name) == nil then
			table.insert(summary.failures, `"{groupFolder.Name}" isn't an item group`)
			continue
		end
		for _, categoryFolder in groupFolder:GetChildren() do
			local isFace = groupFolder.Name == FACE_GROUP and table.find(FACE_CATEGORIES, categoryFolder.Name) ~= nil
			if categoryFolder.Name == "" or categoryFolder.Name:find(ID_DELIMITER, 1, true) then
				table.insert(
					summary.failures,
					`category "{groupFolder.Name}/{categoryFolder.Name}" can't be part of an id`
				)
			end
			for _, item in categoryFolder:GetChildren() do
				if isFace then
					table.insert(
						summary.failures,
						`{groupFolder.Name}/{categoryFolder.Name}/{item.Name}: a template in a face category is never read`
					)
				else
					checkItem(summary, groupFolder.Name, categoryFolder.Name, item)
				end
			end
		end
	end
	-- an anchor that isn't a body part has to come with another item
	for anchorName, ids in summary.mounted do
		if summary.mountCounts[anchorName] == nil then
			for _, id in ids do
				table.insert(summary.failures, `{id}: nothing of the rig or the library is called "{anchorName}"`)
			end
		end
	end

	local libraryCategories: { string } = {}
	local itemCount = 0
	for libraryCategory, count in summary.itemCounts do
		table.insert(libraryCategories, libraryCategory)
		itemCount += count
	end
	table.sort(libraryCategories)
	for _, libraryCategory in libraryCategories do
		print(`  {libraryCategory}: {summary.itemCounts[libraryCategory]}`)
	end
	local meshCount = 0
	for _ in summary.meshIds do
		meshCount += 1
	end
	print(`{itemCount} items, {meshCount} mesh ids`)
	for _, key in TEXTURE_GROUP_KEYS do
		print(`  {key}: {summary.textureGroupCounts[key] or 0} parts`)
	end
	local anchorNames: { string } = {}
	for anchorName in summary.mounted do
		table.insert(anchorNames, anchorName)
	end
	table.sort(anchorNames)
	for _, anchorName in anchorNames do
		print(
			`  {#summary.mounted[anchorName]} items sit on "{anchorName}", `
				.. `which {summary.mountCounts[anchorName] or 0} pieces of the library bring along`
		)
	end
	if cataloguePath then
		print(`held to the tables of "{cataloguePath}"`)
		checkCatalogue(summary, cataloguePath, readImages(place))
	end

	table.sort(summary.failures)
	for _, failure in summary.failures do
		print(`FAIL {failure}`)
	end
	if #summary.failures > 0 then
		print(`{#summary.failures} failure(s) in "{placePath}"`)
		process.exit(1)
	end
	print(`"{placePath}" passed`)
end
