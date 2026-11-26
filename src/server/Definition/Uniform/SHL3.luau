--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
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
-- a piece of an outfit: the item + what the pad colors of it, the rest stays the way the item comes
type Piece = {
	DefinitionId: string,
	Colors: { [TextureGroupKey]: Color3 },
}
-- Constants
-- the three pads of valor city by the id its map marks them with, each as the values the pad of the old place
-- carried: a shirt + pants in a main + a detail color, + a hat that was put on by its name alone. no pattern on any
-- of them. the two near blacks of the details are the old place's own
local ROWS: { [string]: { Piece } } = {
	-- at syndicorp
	ScientistUniform = {
		{
			DefinitionId = "clothing_shirts_overcoat",
			Colors = {
				Primary = Color3.new(1, 1, 1),
				Secondary = Color3.new(0.043137256, 0.043137256, 0.043137256),
			},
		},
		{
			DefinitionId = "clothing_pants_jeans",
			Colors = {
				Primary = Color3.new(0.14901961, 0.14901961, 0.14901961),
				Secondary = Color3.new(0.009, 0.009, 0.009),
			},
		},
	},
	-- up the news tower
	BusinessUniform = {
		{
			DefinitionId = "clothing_shirts_suit-coat",
			Colors = {
				Primary = Color3.new(0, 0, 0),
				Secondary = Color3.new(0.432, 0, 0.0152471),
			},
		},
		{
			DefinitionId = "clothing_pants_jeans",
			Colors = {
				Primary = Color3.new(0, 0, 0),
				Secondary = Color3.new(0.009, 0.009, 0.009),
			},
		},
	},
	-- on the way out of the prison. its cap is a hat that's sold: the pad is the point, whoever takes it off again has
	-- to buy it
	GuardUniform = {
		{
			DefinitionId = "clothing_shirts_jacket",
			Colors = {
				Primary = Color3.new(0.09411766, 0.08627451, 0.07450981),
				Secondary = Color3.new(1, 0, 0),
			},
		},
		{
			DefinitionId = "clothing_pants_jeans",
			Colors = {
				Primary = Color3.new(0.09411766, 0.08627451, 0.07450981),
				Secondary = Color3.new(0.07058824, 0.07058824, 0.07058824),
			},
		},
		{
			DefinitionId = "clothing_hats_cap",
			Colors = {},
		},
	},
}
TableUtil.deepFreeze(ROWS)
-- Variables
local DefinitionCache: { [string]: Result<UniformDefinition, string>? } = {}
-- References
-- Private Functions
local function newItem(piece: Piece): Result<Item, string>
	local definitionId = piece.DefinitionId
	local definitionRes = ItemAppearanceDefinition.get(definitionId)
	if definitionRes.IsErr then
		return Result.err(definitionRes.Value)
	end
	local item: Item = {
		DefinitionId = definitionId,
		TextureGroups = {},
	}
	for key: TextureGroupKey, color in piece.Colors do
		-- a pad only names a color, the rest stays the way the item comes
		local defaultRes = ItemAppearanceDefinition.getDefaultTextureGroup(definitionId, key)
		if defaultRes.IsErr then
			return Result.err(defaultRes.Value)
		end
		item.TextureGroups[key] =
			TextureGroupConstructor.new(color, defaultRes.Value.Material, defaultRes.Value.Transparency)
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
	local pieces = ROWS[id]
	if pieces then
		local items: { Item } = {}
		local problem: string? = nil
		for index, piece in pieces do
			local itemRes = newItem(piece)
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
		out = Result.err(`get "{id}" failed: there's no such outfit`)
	end
	DefinitionCache[id] = out
	return out
end

return Module
