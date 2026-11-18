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
-- Constants
local ID_DELIMITER = "_"
local PATH_DELIMITER = "/"
local TEXTURE_GROUP_KEYS: { TextureGroupKey } = { "Primary", "Secondary", "Tertiary", "Hair", "Skin" }
table.freeze(TEXTURE_GROUP_KEYS)
-- face items have no template in the library, they are images sorted into a folder per slot
local FACE_GROUP: ItemGroup = "cosmetics"
local FACE_IMAGE_EXTENSION = ".png"
-- which slots a face has + the images of each are the game's own, the faces of another game are never required
local FACES: FaceCatalogue = GameDefinition.pick({
	shl1 = function(): FaceCatalogue
		error(`shl1 has no faces yet`)
	end,
	shl2 = function(): FaceCatalogue
		return require("@self/SHL2")
	end,
	shl3 = function(): FaceCatalogue
		error(`shl3 has no faces yet`)
	end,
})
assert(AppearanceType.FaceCatalogue(FACES))
-- a game freezes its own faces, from in here that would reach into the asset table its images are part of
local FACE_SLOTS = FACES.Slots
local FACE_CATEGORIES = FACES.Categories
local FACE_IMAGES = FACES.Images
local FACE_NAMES = FACES.Names
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

-- Class
local Module = {}

for _, slot: FaceSlot in FACE_SLOTS do
	-- a slot that's listed without them is one the checker lets through
	assert(FACE_CATEGORIES[slot] ~= nil, `the "{slot}" face slot has no category`)
	assert(FACE_IMAGES[slot] ~= nil, `the "{slot}" face slot has no images`)
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
	return table.concat({ FACE_GROUP, FACE_CATEGORIES[slot], key }, ID_DELIMITER)
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
			TextureGroups = {},
			Slot = faceSlot,
			Image = image,
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
					table.insert(out, itemDefRes.Value)
				else
					warn(itemDefRes.Value)
				end
			end
		end
	end
	if group == nil or group == FACE_GROUP then
		for _, slot: FaceSlot in FACE_SLOTS do
			if category ~= nil then
				if category ~= FACE_CATEGORIES[slot] then
					continue
				end
			end
			for _, key in getFaceKeys(slot) do
				local itemDefRes = Module.get(Module.getFaceId(slot, key))
				if itemDefRes.IsOk then
					table.insert(out, itemDefRes.Value)
				else
					warn(itemDefRes.Value)
				end
			end
		end
	end
	table.freeze(out)
	return out
end

return Module
