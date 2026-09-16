--!strict
-- Services
-- Packages
-- Modules
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
export type ItemDefinition = AppearanceType.ItemDefinition
type TextureGroupDefinition = AppearanceType.TextureGroupDefinition
type ItemDefinitionTag = AppearanceType.ItemDefinitionTag
type ItemCategory = AppearanceType.ItemCategory
type BuilderImpl = {
	__index: BuilderImpl,
	new: (group: ItemCategory, category: string, item: string) -> Builder,
	addTextureGroup: (self: Builder, textureGroup: TextureGroupDefinition) -> Builder,
	addTag: (self: Builder, tag: ItemDefinitionTag) -> Builder,
	build: (self: Builder) -> ItemDefinition,
}
export type Builder = typeof(setmetatable({} :: { _definition: ItemDefinition }, {} :: BuilderImpl))
-- Constants
-- Variables
-- References
-- Private Functions
local function copyTextureGroup(textureGroup: TextureGroupDefinition): TextureGroupDefinition
	local copy = table.clone(textureGroup)
	local colors = textureGroup.Colors
	local materials = textureGroup.Materials
	if type(colors) == "table" then
		copy.Colors = table.freeze(table.clone(colors))
	end
	if type(materials) == "table" then
		copy.Materials = table.freeze(table.clone(materials))
	end
	return table.freeze(copy)
end

local function copyTextureGroups(textureGroups: { TextureGroupDefinition }): { TextureGroupDefinition }
	local copies: { TextureGroupDefinition } = {}
	for _, textureGroup in textureGroups do
		table.insert(copies, copyTextureGroup(textureGroup))
	end
	return table.freeze(copies)
end

-- Class
local Builder = {} :: BuilderImpl
Builder.__index = Builder

function Builder.new(group: ItemCategory, category: string, item: string): Builder
	local definition: ItemDefinition = {
		Id = `{group}|{category}|{item}`,
		TextureGroups = {},
		Tags = {},
	}
	return setmetatable({
		_definition = definition,
	}, Builder)
end

function Builder.addTextureGroup(self: Builder, textureGroup: TextureGroupDefinition): Builder
	table.insert(self._definition.TextureGroups, copyTextureGroup(textureGroup))
	return self
end

function Builder.addTag(self: Builder, tag: ItemDefinitionTag): Builder
	table.insert(self._definition.Tags, tag)
	return self
end

function Builder.build(self: Builder): ItemDefinition
	assert(AppearanceType.ItemDefinition(self._definition))
	return table.freeze({
		Id = self._definition.Id,
		TextureGroups = copyTextureGroups(self._definition.TextureGroups),
		Tags = table.freeze(table.clone(self._definition.Tags)),
	})
end

return Builder
