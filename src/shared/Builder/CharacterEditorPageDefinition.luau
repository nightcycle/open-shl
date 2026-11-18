--!strict
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type ChoiceDefinition = MiscType.ChoiceDefinition
type Tag = CharacterEditorType.Tag
type ButtonStyle = CharacterEditorType.ButtonStyle
type WearRule = CharacterEditorType.WearRule
type ProfileBinding = CharacterEditorType.ProfileBinding
type ChooseBinding = CharacterEditorType.ChooseBinding
type PowersBinding = CharacterEditorType.PowersBinding
type PowerLimitBinding = CharacterEditorType.PowerLimitBinding
type ColorBinding = CharacterEditorType.ColorBinding
type ItemTextureBinding = CharacterEditorType.ItemTextureBinding
type FieldDefinition = CharacterEditorType.FieldDefinition
type PageDefinition = CharacterEditorType.PageDefinition

-- the binding leads every field that has one, it's the piece of the character the field edits
export type Builder = {
	setTitle: (self: Builder, title: string?) -> Builder,
	setShared: (self: Builder) -> Builder,
	setStandIn: (self: Builder, definitionId: string) -> Builder,
	insertTextField: (
		self: Builder,
		binding: ProfileBinding,
		description: string?,
		maxLength: number?,
		isMultiLine: boolean?,
		exclusionTags: { Tag }?
	) -> Builder,
	insertSectionHeaderField: (
		self: Builder,
		text: string,
		binding: PowerLimitBinding?,
		exclusionTags: { Tag }?
	) -> Builder,
	insertChooseField: (
		self: Builder,
		binding: ChooseBinding,
		choices: { ChoiceDefinition },
		description: string?,
		isVertical: boolean?,
		exclusionTags: { Tag }?
	) -> Builder,
	insertChoiceListField: (
		self: Builder,
		binding: PowersBinding,
		choices: { ChoiceDefinition },
		description: string?,
		exclusionTags: { Tag }?
	) -> Builder,
	insertColorField: (
		self: Builder,
		binding: ColorBinding,
		description: string?,
		filtered: { Color3 }?,
		exclusionTags: { Tag }?
	) -> Builder,
	insertMaterialField: (
		self: Builder,
		binding: ItemTextureBinding,
		description: string?,
		filtered: { Enum.Material }?,
		exclusionTags: { Tag }?
	) -> Builder,
	insertPatternField: (
		self: Builder,
		binding: ItemTextureBinding,
		description: string?,
		exclusionTags: { Tag }?
	) -> Builder,
	insertToggleField: (
		self: Builder,
		focus: Tag,
		text: string,
		style: ButtonStyle,
		disabledText: string?,
		sections: { FieldDefinition }?,
		disabledSections: { FieldDefinition }?,
		exclusionTags: { Tag }?
	) -> Builder,
	insertExclusionTag: (self: Builder, tag: Tag) -> Builder,
	insertGenerateAliasField: (self: Builder, binding: ProfileBinding, exclusionTags: { Tag }?) -> Builder,
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
			local properties = table.clone(definition.Fields or {})
			table.insert(properties, field)
			-- selene: allow(if_same_then_else)
			if definition.Type == "Default" then
				definition.Fields = properties
			else
				definition.Fields = properties
			end
			return definition
		end)
	end

	local out: Builder = {
		setTitle = function(_: Builder, title: string?): Builder
			return builder(priorDefinition, function(definition: PageDefinition): PageDefinition
				if definition.Type == "Item" then
					warn(`Cannot set Title on Item page "{definition.DefinitionId}"; only Default pages support Title`)
					return definition
				end
				definition.Title = title
				return definition
			end)
		end,
		setShared = function(_: Builder): Builder
			return builder(priorDefinition, function(definition: PageDefinition): PageDefinition
				-- selene: allow(if_same_then_else)
				if definition.Type == "Default" then
					definition.IsShared = true
				else
					definition.IsShared = true
				end
				return definition
			end)
		end,
		setStandIn = function(_: Builder, definitionId: string): Builder
			return builder(priorDefinition, function(definition: PageDefinition): PageDefinition
				if definition.Type == "Default" then
					warn(`Cannot set a stand-in on page "{definition.Key}"; only Item pages are worn`)
					return definition
				end
				definition.StandInId = definitionId
				return definition
			end)
		end,
		insertExclusionTag = function(_: Builder, tag: Tag): Builder
			return builder(priorDefinition, function(definition: PageDefinition): PageDefinition
				local tags: { Tag } = table.clone(definition.ExclusionTags or {})
				table.insert(tags, tag)
				-- selene: allow(if_same_then_else)
				if definition.Type == "Default" then
					definition.ExclusionTags = tags
				else
					definition.ExclusionTags = tags
				end
				return definition
			end)
		end,
		insertTextField = function(
			_: Builder,
			binding: ProfileBinding,
			description: string?,
			maxLength: number?,
			isMultiLine: boolean?,
			exclusionTags: { Tag }?
		): Builder
			return insertField({
				Type = "Text",
				Binding = binding,
				Description = description,
				MaxLength = maxLength,
				IsMultiLine = isMultiLine,
				ExclusionTags = exclusionTags,
			})
		end,
		insertSectionHeaderField = function(
			_: Builder,
			text: string,
			binding: PowerLimitBinding?,
			exclusionTags: { Tag }?
		): Builder
			return insertField({
				Type = "SectionHeader",
				Text = text,
				Binding = binding,
				ExclusionTags = exclusionTags,
			})
		end,
		insertChooseField = function(
			_: Builder,
			binding: ChooseBinding,
			choices: { ChoiceDefinition },
			description: string?,
			isVertical: boolean?,
			exclusionTags: { Tag }?
		): Builder
			return insertField({
				Type = "Choose",
				Binding = binding,
				Description = description,
				Choices = choices,
				IsVertical = isVertical,
				ExclusionTags = exclusionTags,
			})
		end,
		insertChoiceListField = function(
			_: Builder,
			binding: PowersBinding,
			choices: { ChoiceDefinition },
			description: string?,
			exclusionTags: { Tag }?
		): Builder
			return insertField({
				Type = "ChoiceList",
				Binding = binding,
				Description = description,
				Choices = choices,
				ExclusionTags = exclusionTags,
			})
		end,
		insertColorField = function(
			_: Builder,
			binding: ColorBinding,
			description: string?,
			filtered: { Color3 }?,
			exclusionTags: { Tag }?
		): Builder
			return insertField({
				Type = "Color",
				Binding = binding,
				Description = description,
				Filtered = filtered,
				ExclusionTags = exclusionTags,
			})
		end,
		insertMaterialField = function(
			_: Builder,
			binding: ItemTextureBinding,
			description: string?,
			filtered: { Enum.Material }?,
			exclusionTags: { Tag }?
		): Builder
			return insertField({
				Type = "Material",
				Binding = binding,
				Description = description,
				Filtered = filtered,
				ExclusionTags = exclusionTags,
			})
		end,
		insertPatternField = function(
			_: Builder,
			binding: ItemTextureBinding,
			description: string?,
			exclusionTags: { Tag }?
		): Builder
			return insertField({
				Type = "Pattern",
				Binding = binding,
				Description = description,
				ExclusionTags = exclusionTags,
			})
		end,
		insertToggleField = function(
			_: Builder,
			focus: Tag,
			text: string,
			style: ButtonStyle,
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
		insertGenerateAliasField = function(_: Builder, binding: ProfileBinding, exclusionTags: { Tag }?): Builder
			return insertField({ Type = "GenerateAlias", Binding = binding, ExclusionTags = exclusionTags })
		end,
		addChild = function(_: Builder, child: PageDefinition): Builder
			return builder(priorDefinition, function(definition: PageDefinition): PageDefinition
				if definition.Type == "Item" then
					warn(
						`Cannot add Children to Item page "{definition.DefinitionId}"; only Default pages support Children`
					)
					return definition
				end
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
	new = function(key: string): Builder
		return builder({ Type = "Default", Key = key })
	end,
	-- an item swaps out what's worn of its category unless a rule says otherwise
	newItem = function(definitionId: string, wearRule: WearRule?): Builder
		return builder({ Type = "Item", DefinitionId = definitionId, WearRule = wearRule or "Single" })
	end,
})
