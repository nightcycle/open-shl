--!strict
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type ChoiceDefinition = MiscType.ChoiceDefinition
type Tag = CharacterEditorType.Tag
type FieldDefinition = CharacterEditorType.FieldDefinition
type PageDefinition = CharacterEditorType.PageDefinition

export type Builder = {
	setTitle: (self: Builder, title: string?) -> Builder,
	addField: (self: Builder, field: FieldDefinition) -> Builder,
	insertTextField: (self: Builder, description: string, maxLength: number?, exclusionTags: { Tag }?) -> Builder,
	insertChooseField: (
		self: Builder,
		description: string,
		choices: { ChoiceDefinition },
		exclusionTags: { Tag }?
	) -> Builder,
	insertChoiceListField: (
		self: Builder,
		description: string,
		choices: { ChoiceDefinition },
		exclusionTags: { Tag }?
	) -> Builder,
	insertColorField: (self: Builder, description: string, filtered: { Color3 }?, exclusionTags: { Tag }?) -> Builder,
	insertMaterialField: (self: Builder, filtered: { Enum.Material }?, exclusionTags: { Tag }?) -> Builder,
	insertToggleField: (
		self: Builder,
		focus: Tag,
		text: string,
		style: "Outline" | "Filled",
		disabledText: string?,
		sections: { FieldDefinition }?,
		disabledSections: { FieldDefinition }?,
		exclusionTags: { Tag }?
	) -> Builder,
	insertButtonField: (
		self: Builder,
		text: string,
		alignment: Enum.HorizontalAlignment,
		exclusionTags: { Tag }?
	) -> Builder,
	addChild: (self: Builder, child: PageDefinition) -> Builder,
	build: (self: Builder) -> PageDefinition,
}
-- Private Functions
local function builder(priorDefinition: PageDefinition, fn: ((PageDefinition) -> PageDefinition)?): Builder
	priorDefinition = table.clone(priorDefinition)
	if fn then
		priorDefinition = fn(priorDefinition)
	end
	priorDefinition = TableUtil.deepCopy(priorDefinition)
	assert(CharacterEditorType.PageDefinition(priorDefinition))
	TableUtil.deepFreeze(priorDefinition)

	local function insertField(field: FieldDefinition): Builder
		return builder(priorDefinition, function(definition: PageDefinition): PageDefinition
			local properties = table.clone(definition.Properties or {})
			table.insert(properties, field)
			definition.Properties = properties
			return definition
		end)
	end

	local out: Builder = {
		setTitle = function(_: Builder, title: string?): Builder
			return builder(priorDefinition, function(definition: PageDefinition): PageDefinition
				definition.Title = title
				return definition
			end)
		end,
		addField = function(_: Builder, field: FieldDefinition): Builder
			return insertField(field)
		end,
		insertTextField = function(
			_: Builder,
			description: string,
			maxLength: number?,
			exclusionTags: { Tag }?
		): Builder
			return insertField({
				Type = "Text",
				Description = description,
				MaxLength = maxLength,
				ExclusionTags = exclusionTags,
			})
		end,
		insertChooseField = function(
			_: Builder,
			description: string,
			choices: { ChoiceDefinition },
			exclusionTags: { Tag }?
		): Builder
			return insertField({
				Type = "Choose",
				Description = description,
				Choices = choices,
				ExclusionTags = exclusionTags,
			})
		end,
		insertChoiceListField = function(
			_: Builder,
			description: string,
			choices: { ChoiceDefinition },
			exclusionTags: { Tag }?
		): Builder
			return insertField({
				Type = "ChoiceList",
				Description = description,
				Choices = choices,
				ExclusionTags = exclusionTags,
			})
		end,
		insertColorField = function(
			_: Builder,
			description: string,
			filtered: { Color3 }?,
			exclusionTags: { Tag }?
		): Builder
			return insertField({
				Type = "Color",
				Description = description,
				Filtered = filtered,
				ExclusionTags = exclusionTags,
			})
		end,
		insertMaterialField = function(_: Builder, filtered: { Enum.Material }?, exclusionTags: { Tag }?): Builder
			return insertField({ Type = "Material", Filtered = filtered, ExclusionTags = exclusionTags })
		end,
		insertToggleField = function(
			_: Builder,
			focus: Tag,
			text: string,
			style: "Outline" | "Filled",
			disabledText: string?,
			sections: { FieldDefinition }?,
			disabledSections: { FieldDefinition }?,
			exclusionTags: { Tag }?
		): Builder
			return insertField({
				Type = "Toggle",
				Focus = focus,
				Text = text,
				Style = style,
				DisabledText = disabledText,
				Sections = sections,
				DisabledSections = disabledSections,
				ExclusionTags = exclusionTags,
			})
		end,
		insertButtonField = function(
			_: Builder,
			text: string,
			alignment: Enum.HorizontalAlignment,
			exclusionTags: { Tag }?
		): Builder
			return insertField({ Type = "Button", Text = text, Alignment = alignment, ExclusionTags = exclusionTags })
		end,
		addChild = function(_: Builder, child: PageDefinition): Builder
			return builder(priorDefinition, function(definition: PageDefinition): PageDefinition
				local children = table.clone(definition.Children or {})
				table.insert(children, child)
				definition.Children = children
				return definition
			end)
		end,
		build = function(_: Builder): PageDefinition
			return priorDefinition
		end,
	}
	return table.freeze(out)
end
-- Class
return table.freeze({
	fromDefinition = function(definition: PageDefinition): Builder
		return builder(definition)
	end,
	new = function(key: string, exclusionTags: { Tag }?): Builder
		return builder({ Key = key, ExclusionTags = exclusionTags })
	end,
})
