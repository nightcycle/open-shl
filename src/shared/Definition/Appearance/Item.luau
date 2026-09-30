--!strict
--!native
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
export type ItemDefinitionIndex = AppearanceType.ItemDefinitionIndex
-- Constants
-- Variables
-- References
local DefinitionIndexCache: { [string]: ItemDefinitionIndex? } = {}
-- Private Functions
-- Class
local Module = {}

Module.getItemDefinitionIndexFromId = function(id: string): Result<ItemDefinitionIndex, string>
	do
		local cachedValue = DefinitionIndexCache[id]
		if cachedValue then
			return TypeUnionLib.Result.ok(cachedValue)
		end
	end
	local keys = id:split("|")
	if #keys == 3 then
		local group = keys[1]
		do
			local success, msg = AppearanceType.ItemGroup(group)
			if not success then
				return TypeUnionLib.Result.err(msg)
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
		return TypeUnionLib.Result.ok(defIndex)
	else
		return TypeUnionLib.Result.err(`expected 3 keys from "{id}", received {#keys}`)
	end
end

Module.getIdFromItemDefinitionIndex = function(definitionIndex: ItemDefinitionIndex): string
	return `{definitionIndex.Group}|{definitionIndex.Category}|{definitionIndex.Key}`
end

return Module
