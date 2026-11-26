--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local LegacyDataMigration = require("@game/ServerScriptService/Server/Util/LegacyDataMigration")
local TextureGroupConstructor =
	require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item/TextureGroup")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Item = AppearanceType.Item
type TextureGroupKey = AppearanceType.TextureGroupKey
-- the definition asks for this file, so the type is spelt out here
type UniformDefinition = {
	Id: string,
	Items: { Item },
}
-- Constants
-- the one part of a piece of clothing an outfit gets to color
local TEXTURE_GROUP_KEY: TextureGroupKey = "Primary"
-- Variables
local DefinitionCache: { [string]: Result<UniformDefinition, string>? } = {}
-- References
-- each json file of the folder is a module named after the uniform it holds
local Outfits = IndexUtil.waitForPath("game/ServerScriptService/Data/legacy/outfit") :: Folder
-- Private Functions
local function newItem(outfitItem: LegacyDataMigration.Item): Result<Item, string>
	local definitionId = outfitItem.Name
	local definitionRes = ItemAppearanceDefinition.get(definitionId)
	if definitionRes.IsErr then
		return Result.err(definitionRes.Value)
	end
	local item: Item = {
		DefinitionId = definitionId,
		TextureGroups = {},
	}
	local texture = outfitItem.Primary
	if texture and table.find(definitionRes.Value.TextureGroups, TEXTURE_GROUP_KEY) then
		-- an outfit only names a color + a material, the rest stays the way the item comes
		local defaultRes = ItemAppearanceDefinition.getDefaultTextureGroup(definitionId, TEXTURE_GROUP_KEY)
		if defaultRes.IsErr then
			return Result.err(defaultRes.Value)
		end
		item.TextureGroups[TEXTURE_GROUP_KEY] = TextureGroupConstructor.new(
			texture.BrickColor.Color,
			texture.Material or defaultRes.Value.Material,
			defaultRes.Value.Transparency
		)
	end
	return Result.ok(item)
end
-- Class
local Module = {}

Module.get = function(id: string): Result<UniformDefinition, string>
	do
		local cachedValue = DefinitionCache[id]
		if cachedValue then
			return cachedValue
		end
	end
	local out: Result<UniformDefinition, string>
	local outfitModule = Outfits:FindFirstChild(id)
	if outfitModule and outfitModule:IsA("ModuleScript") then
		-- required by instance, rojo turns each json into a module
		local outfitRes = LegacyDataMigration.convertOutfit(require(outfitModule) :: unknown)
		if outfitRes.IsOk then
			local items: { Item } = {}
			local problem: string? = nil
			for index, outfitItem in outfitRes.Value.Items do
				local itemRes = newItem(outfitItem)
				if itemRes.IsErr then
					problem = `item {index}: {itemRes.Value}`
					break
				end
				table.insert(items, itemRes.Value)
			end
			if problem then
				out = Result.err(`get "{id}" failed: {problem}`)
			else
				local definition: UniformDefinition = {
					Id = id,
					Items = items,
				}
				TableUtil.deepFreeze(definition)
				out = Result.ok(definition)
			end
		else
			out = Result.err(`get "{id}" failed: {outfitRes.Value}`)
		end
	else
		out = Result.err(`get "{id}" failed: there's no such outfit`)
	end
	DefinitionCache[id] = out
	return out
end

return Module
