--!strict
--!native
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local TextureGroupConstructor =
	require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item/TextureGroup")
-- Types
type ToDo<V, Progress...> = TypeUnionLib.ToDo<V, Progress...>
type Result<V, E> = TypeUnionLib.Result<V, E>
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
export type ItemDefinitionIndex = AppearanceType.ItemDefinitionIndex
export type ItemDefinition = AppearanceType.ItemDefinition
type ItemGroup = AppearanceType.ItemGroup
type TextureGroupKey = AppearanceType.TextureGroupKey
type TextureGroup = AppearanceType.TextureGroup
type FaceSlot = AppearanceType.FaceSlot
type FaceCatalogue = AppearanceType.FaceCatalogue
type ItemOrder = AppearanceType.ItemOrder
-- Constants
local ID_DELIMITER = "_"
local PATH_DELIMITER = "/"
local TEXTURE_GROUP_KEYS: { TextureGroupKey } = { "Primary", "Secondary", "Tertiary", "Hair", "Skin" }
table.freeze(TEXTURE_GROUP_KEYS)
-- what a template says about the body under it: the part it's worn on isn't drawn, hair isn't
local BODY_HIDDEN_ATTRIBUTE = "IsBodyHidden"
local SHAVE_HEAD_ATTRIBUTE = "ShaveHead"
-- face items have no template in the library, they are images sorted into a folder per slot
local FACE_GROUP: ItemGroup = "cosmetics"
local FACE_IMAGE_EXTENSION = ".png"
-- the one group a face item of a tinted slot lists, its color is what the image is drawn in
local FACE_TINT_GROUP_KEY: TextureGroupKey = "Primary"
-- which slots a face has + the images of each are the game's own, the faces of another game are never required
local FACES: FaceCatalogue = GameDefinition.pick({
	shl1 = function(): FaceCatalogue
		return require("@self/SHL1")
	end,
	shl2 = function(): FaceCatalogue
		return require("@self/SHL2")
	end,
	shl3 = function(): FaceCatalogue
		return require("@self/SHL3")
	end,
})
assert(AppearanceType.FaceCatalogue(FACES))
-- a game freezes its own faces, from in here that would reach into the asset table its images are part of
local FACE_SLOTS = FACES.Slots
local FACE_CATEGORIES = FACES.Categories
local FACE_IMAGES = FACES.Images
local FACE_NAMES = FACES.Names
local FACE_DEFAULTS = FACES.Defaults
local FACE_TINTS = FACES.Tints
-- the categories the game lists in an order of its own, by "<group>/<category>". none in a game that lists every one
-- the way the library holds it
local ORDERS: { [string]: ItemOrder } = FACES.Orders or table.freeze({})
-- Variables
local DefinitionIndexCache: { [string]: ItemDefinitionIndex? } = {}
local TemplateCache: { [string]: Instance? } = {}
local DefinitionCache: { [string]: Result<ItemDefinition, string>? } = {}
-- References
local CharacterLibrary = IndexUtil.waitForPath("game/ReplicatedStorage/lib/character")
-- Private Functions
local function getTextureGroups(template: Instance): { TextureGroupKey }
	local instances = template:GetDescendants()
	table.insert(instances, 1, template)
	local usedGroups: { [string]: boolean } = {}
	for _, inst in instances do
		if inst:IsA("BasePart") then
			local group = inst:GetAttribute("TextureGroup")
			if type(group) == "string" then
				usedGroups[group] = true
			end
		end
	end

	local groups: { TextureGroupKey } = {}
	for _, group in TEXTURE_GROUP_KEYS do
		if usedGroups[group] then
			table.insert(groups, group)
		end
	end
	return groups
end

local function getFaceSlot(defIndex: ItemDefinitionIndex): FaceSlot?
	if defIndex.Group ~= FACE_GROUP then
		return nil
	end
	for _, slot: FaceSlot in FACE_SLOTS do
		if FACE_CATEGORIES[slot] == defIndex.Category then
			return slot
		end
	end
	return nil
end

local function getFaceKeys(slot: FaceSlot): { string }
	local keys: { string } = {}
	for fileName in FACE_IMAGES[slot] do
		if fileName:sub(-#FACE_IMAGE_EXTENSION) == FACE_IMAGE_EXTENSION then
			table.insert(keys, fileName:sub(1, -#FACE_IMAGE_EXTENSION - 1))
		end
	end
	-- dictionaries have no order, sorting keeps lists + seeded picks stable
	table.sort(keys)
	return keys
end

local function getFaceName(slot: FaceSlot, id: string, key: string): string
	return FACE_NAMES[id] or `{key:sub(1, 1):upper()}{key:sub(2)} {slot}`
end

-- where an item is on the list of its category + whether it's anybody's. nil for both in a category the game lists
-- the way the library holds it, an item the list of its category leaves out has no place + is nobody's
local function getOrder(defIndex: ItemDefinitionIndex): (number?, boolean?)
	local order = ORDERS[`{defIndex.Group}{PATH_DELIMITER}{defIndex.Category}`]
	if order == nil then
		return nil, nil
	end
	local index = table.find(order.Keys, defIndex.Key)
	return index, index ~= nil and index <= (order.StarterCount or #order.Keys)
end

-- the items of one category the way the game lists them: the ones with a place first, in that order, then the rest
-- the way they came
local function insertOrdered(out: { ItemDefinition }, definitions: { ItemDefinition })
	local placed: { [number]: ItemDefinition } = {}
	local last = 0
	for _, definition in definitions do
		if definition.Order then
			placed[definition.Order] = definition
			last = math.max(last, definition.Order)
		end
	end
	for index = 1, last do
		local definition = placed[index]
		if definition then
			table.insert(out, definition)
		end
	end
	for _, definition in definitions do
		if definition.Order == nil then
			table.insert(out, definition)
		end
	end
end

-- Class
-- the key is in from the start, as a field that's assigned afterwards the checker only knows it for a string
local Module = {
	FACE_TINT_GROUP_KEY = FACE_TINT_GROUP_KEY,
}

for _, slot: FaceSlot in FACE_SLOTS do
	-- a slot that's listed without them is one the checker lets through
	assert(FACE_CATEGORIES[slot] ~= nil, `the "{slot}" face slot has no category`)
	assert(FACE_IMAGES[slot] ~= nil, `the "{slot}" face slot has no images`)
	local defaultKey = FACE_DEFAULTS[slot]
	assert(
		defaultKey == nil or FACE_IMAGES[slot][`{defaultKey}{FACE_IMAGE_EXTENSION}`] ~= nil,
		`the "{slot}" face slot has no "{defaultKey}" image to fall back on`
	)
end

-- from the top of a face down
Module.listFaceSlots = function(): { FaceSlot }
	return FACE_SLOTS
end

Module.getIndex = function(id: string): Result<ItemDefinitionIndex, string>
	do
		local cachedValue = DefinitionIndexCache[id]
		if cachedValue then
			return Result.ok(cachedValue)
		end
	end
	local keys = id:split(ID_DELIMITER)
	if #keys == 3 then
		local group = keys[1]
		do
			local success, msg = AppearanceType.ItemGroup(group)
			if not success then
				return Result.err(msg)
			end
		end
		local category = keys[2]
		local item = keys[3]
		-- a path inside of a key would resolve to the insides of a template
		for _, key in keys do
			if key == "" or key:find(PATH_DELIMITER, 1, true) then
				return Result.err(`bad key "{key}" in "{id}"`)
			end
		end
		local defIndex: ItemDefinitionIndex = table.freeze({
			Group = group :: AppearanceType.ItemGroup,
			Category = category,
			Key = item,
		})
		DefinitionIndexCache[id] = defIndex
		return Result.ok(defIndex)
	else
		return Result.err(`expected 3 keys from "{id}", received {#keys}`)
	end
end

Module.getIdFromIndex = function(definitionIndex: ItemDefinitionIndex): string
	return table.concat({ definitionIndex.Group, definitionIndex.Category, definitionIndex.Key }, ID_DELIMITER)
end

Module.getFaceId = function(slot: FaceSlot, key: string): string
	local category = FACE_CATEGORIES[slot]
	-- a slot of another game's faces is one the checker lets through
	assert(category ~= nil, `the game has no "{slot}" face slot`)
	return table.concat({ FACE_GROUP, category, key }, ID_DELIMITER)
end

-- what a slot shows with nothing worn in it, nil for a slot that stays bare
Module.getDefaultFaceId = function(slot: FaceSlot): string?
	local key = FACE_DEFAULTS[slot]
	return if key then Module.getFaceId(slot, key) else nil
end

-- the color the images of a slot are drawn in until an item brings its own, nil for a slot that isn't tinted
Module.getFaceTint = function(slot: FaceSlot): Color3?
	return FACE_TINTS[slot]
end

Module.getTemplate = function(id: string): Result<Instance, string>
	do
		local cachedValue = TemplateCache[id]
		if cachedValue then
			return Result.ok(cachedValue)
		end
	end
	do
		local indexRes = Module.getIndex(id)
		if indexRes.IsErr then
			return Result.err(`template "{id}" failed: {indexRes.Value}`)
		end
		if getFaceSlot(indexRes.Value) then
			return Result.err(`"{id}" is a face item, it has no template`)
		end
	end
	local keys = id:split(ID_DELIMITER)
	local templateRes = IndexUtil.tryFirstLocalPath(CharacterLibrary, table.concat(keys, PATH_DELIMITER))
	if templateRes.IsOk then
		TemplateCache[id] = templateRes.Value
	end
	return templateRes
end

Module.get = function(id: string): Result<ItemDefinition, string>
	do
		local cachedValue = DefinitionCache[id]
		if cachedValue then
			return cachedValue
		end
	end
	local indexRes = Module.getIndex(id)
	if indexRes.IsErr then
		return Result.err(`get "{id}" failed: {indexRes.Value}`)
	end

	local itemDefinition: ItemDefinition
	local order, isStarter = getOrder(indexRes.Value)
	local faceSlot: FaceSlot? = getFaceSlot(indexRes.Value)
	if faceSlot then
		local image: string? = FACE_IMAGES[faceSlot][`{indexRes.Value.Key}{FACE_IMAGE_EXTENSION}`]
		if image == nil then
			return Result.err(`get "{id}" failed: no "{faceSlot}" image for "{indexRes.Value.Key}"`)
		end
		itemDefinition = {
			Type = "Face",
			Id = id,
			Name = getFaceName(faceSlot, id, indexRes.Value.Key),
			Tags = {},
			TextureGroups = if FACE_TINTS[faceSlot] then { FACE_TINT_GROUP_KEY } else {},
			Slot = faceSlot,
			Image = image,
			Order = order,
			IsStarter = isStarter,
		}
	else
		local itemDefRes = Module.getTemplate(id)
		if itemDefRes.IsErr then
			return Result.err(`get "{id}" failed: {itemDefRes.Value}`)
		end
		itemDefinition = {
			Type = "Model",
			Id = id,
			Name = itemDefRes.Value:GetAttribute("Name") :: string?,
			Rarity = itemDefRes.Value:GetAttribute("Rarity") :: PseudoEnum.Rarity?,
			Tags = itemDefRes.Value:GetTags(),
			TextureGroups = getTextureGroups(itemDefRes.Value),
			-- only what a template says is so, one that says nothing is like one from before either was asked
			IsBodyHidden = if itemDefRes.Value:GetAttribute(BODY_HIDDEN_ATTRIBUTE) == true then true else nil,
			ShaveHead = if itemDefRes.Value:GetAttribute(SHAVE_HEAD_ATTRIBUTE) == true then true else nil,
			Order = order,
			IsStarter = isStarter,
		}
	end
	TableUtil.deepFreeze(itemDefinition)
	do
		local success, msg = AppearanceType.ItemDefinition(itemDefinition)
		if not success then
			local e = Result.err(`get "{id}" failed type validation: {msg}`)
			DefinitionCache[id] = e
			return e
		end
	end
	local out = Result.ok(itemDefinition)
	DefinitionCache[id] = out
	return out
end

Module.getDefaultTextureGroup = function(id: string, key: TextureGroupKey): Result<TextureGroup, string>
	do
		-- a face item has no template to read a color off
		local indexRes = Module.getIndex(id)
		local faceSlot: FaceSlot? = if indexRes.IsOk then getFaceSlot(indexRes.Value) else nil
		local tint: Color3? = if faceSlot then FACE_TINTS[faceSlot] else nil
		if tint and key == FACE_TINT_GROUP_KEY then
			return Result.ok(TextureGroupConstructor.new(tint))
		end
	end
	local templateRes = Module.getTemplate(id)
	if templateRes.IsErr then
		return Result.err(`default "{key}" of "{id}" failed: {templateRes.Value}`)
	end
	local instances = templateRes.Value:GetDescendants()
	table.insert(instances, 1, templateRes.Value)
	for _, inst in instances do
		if inst:IsA("BasePart") and inst:GetAttribute("TextureGroup") == key then
			return Result.ok(TextureGroupConstructor.new(inst.Color, inst.Material, inst.Transparency))
		end
	end
	return Result.err(`"{id}" has no "{key}" texture group`)
end

Module.listCategories = function(group: ItemGroup?): { string }
	local out = {}
	for _, groupFolder in CharacterLibrary:GetChildren() do
		if group ~= nil then
			if group ~= groupFolder.Name then
				continue
			end
		end
		for _, categoryFolder in groupFolder:GetChildren() do
			table.insert(out, categoryFolder.Name)
		end
	end
	if group == nil or group == FACE_GROUP then
		for _, slot: FaceSlot in FACE_SLOTS do
			table.insert(out, FACE_CATEGORIES[slot])
		end
	end
	table.freeze(out)
	return out
end

Module.list = function(group: ItemGroup?, category: string?): { ItemDefinition }
	local out = {}
	for _, groupFolder in CharacterLibrary:GetChildren() do
		if group ~= nil then
			if group ~= groupFolder.Name then
				continue
			end
		end
		for _, categoryFolder in groupFolder:GetChildren() do
			if category ~= nil then
				if category ~= categoryFolder.Name then
					continue
				end
			end
			local definitions: { ItemDefinition } = {}
			for _, item in categoryFolder:GetChildren() do
				local defIndex: ItemDefinitionIndex = {
					Group = groupFolder.Name :: AppearanceType.ItemGroup,
					Category = categoryFolder.Name,
					Key = item.Name,
				}
				table.freeze(defIndex)
				local id = Module.getIdFromIndex(defIndex)
				local itemDefRes = Module.get(id)
				if itemDefRes.IsOk then
					table.insert(definitions, itemDefRes.Value)
				else
					warn(itemDefRes.Value)
				end
			end
			insertOrdered(out, definitions)
		end
	end
	if group == nil or group == FACE_GROUP then
		for _, slot: FaceSlot in FACE_SLOTS do
			if category ~= nil then
				if category ~= FACE_CATEGORIES[slot] then
					continue
				end
			end
			local definitions: { ItemDefinition } = {}
			for _, key in getFaceKeys(slot) do
				local itemDefRes = Module.get(Module.getFaceId(slot, key))
				if itemDefRes.IsOk then
					table.insert(definitions, itemDefRes.Value)
				else
					warn(itemDefRes.Value)
				end
			end
			insertOrdered(out, definitions)
		end
	end
	table.freeze(out)
	return out
end

-- a list that names an item the game doesn't have, or one twice, is one the checker lets through
for path, order in ORDERS do
	local keys = path:split(PATH_DELIMITER)
	assert(#keys == 2 and AppearanceType.ItemGroup(keys[1]), `bad category "{path}" in the item orders`)
	local seen: { [string]: true } = {}
	for _, key in order.Keys do
		assert(not seen[key], `"{key}" is on the list of "{path}" twice`)
		seen[key] = true
		local id = table.concat({ keys[1], keys[2], key }, ID_DELIMITER)
		local itemDefRes = Module.get(id)
		assert(itemDefRes.IsOk, `the list of "{path}" names "{key}": {itemDefRes.Value}`)
	end
end

return Module
