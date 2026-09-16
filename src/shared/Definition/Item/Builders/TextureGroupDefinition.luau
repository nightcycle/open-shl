--!strict
-- Services
-- Packages
-- Modules
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Appearance")
export type TextureGroupDefinition = AppearanceType.TextureGroupDefinition

type BuilderImpl = {
	__index: BuilderImpl,
	new: (key: string) -> Builder,
	setTransparency: (self: Builder, transparency: NumberRange | number?) -> Builder,
	setColors: (self: Builder, colors: { Color3 } | true?) -> Builder,
	setMaterials: (self: Builder, materials: { Enum.Material } | true?) -> Builder,
	build: (self: Builder) -> TextureGroupDefinition,
}
export type Builder = typeof(setmetatable({} :: { _definition: TextureGroupDefinition }, {} :: BuilderImpl))
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Builder = {} :: BuilderImpl
Builder.__index = Builder

function Builder.new(key: string): Builder
	local definition: TextureGroupDefinition = {
		Key = key,
	}
	return setmetatable({
		_definition = definition,
	}, Builder)
end

function Builder.setTransparency(self: Builder, transparency: NumberRange | number?): Builder
	self._definition.Transparency = transparency
	return self
end

function Builder.setColors(self: Builder, colors: { Color3 } | true?): Builder
	self._definition.Colors = if type(colors) == "table" then table.clone(colors) else colors
	return self
end

function Builder.setMaterials(self: Builder, materials: { Enum.Material } | true?): Builder
	self._definition.Materials = if type(materials) == "table" then table.clone(materials) else materials
	return self
end

function Builder.build(self: Builder): TextureGroupDefinition
	assert(AppearanceType.TextureGroupDefinition(self._definition))
	local definition = table.clone(self._definition)
	local colors = definition.Colors
	local materials = definition.Materials
	if type(colors) == "table" then
		definition.Colors = table.freeze(table.clone(colors))
	end
	if type(materials) == "table" then
		definition.Materials = table.freeze(table.clone(materials))
	end
	return table.freeze(definition)
end

return Builder
