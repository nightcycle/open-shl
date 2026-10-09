--!strict
--!native
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
type ToDo<V, Progress...> = TypeUnionLib.ToDo<V, Progress...>
type Result<V, E> = TypeUnionLib.Result<V, E>
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
export type ItemDefinitionIndex = AppearanceType.ItemDefinitionIndex
export type ItemDefinition = AppearanceType.ItemDefinition
-- Constants
local ID_DELIMITER = "/"
-- Variables
local DefinitionIndexCache: { [string]: ItemDefinitionIndex? } = {}
local TemplateCache: { [string]: Instance? } = {}
local DefinitionCache: { [string]: Result<ItemDefinition, string>? } = {}
-- References
local CharacterLibrary = IndexUtil.waitForPath("game/ReplicatedStorage/lib/character")
-- Private Functions
-- Class
local Module = {}

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

Module.getTemplate = function(id: string): Result<Instance, string>
	do
		local cachedValue = TemplateCache[id]
		if cachedValue then
			return Result.ok(cachedValue)
		end
	end
	local keys = id:split(ID_DELIMITER)
	local templateRes = IndexUtil.tryFirstLocalPath(CharacterLibrary, table.concat(keys, "/"))
	if templateRes.IsOk then
		TemplateCache[id] = templateRes.Value
	end
	return templateRes
end

Module.get = function(id: string): Result<ItemDefinition, string>
	local itemDefRes = Module.getTemplate(id)
	if itemDefRes.IsErr then
		return Result.err(`get "{id}" failed: {itemDefRes.Value}`)
	end
	do
		local cachedValue = DefinitionCache[id]
		if cachedValue then
			return cachedValue
		end
	end

	local itemDefinition: ItemDefinition = {
		Id = id,
		Name = itemDefRes.Value:GetAttribute("Name") :: string?,
		Rarity = itemDefRes.Value:GetAttribute("Rarity") :: PseudoEnum.Rarity?,
		Tags = itemDefRes.Value:GetTags(),
		TextureGroups = {},
	}
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

Module.list = function(group: AppearanceType.ItemGroup?, category: string?): { ItemDefinition }
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
	table.freeze(out)
	return out
end

return Module
