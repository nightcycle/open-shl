--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
local FieldComponents = {
	ChoiceList = require("@self/ChoiceList"),
	Choose = require("@self/Choose"),
	GenerateAlias = require("@self/GenerateAlias"),
	Material = require("@self/Material"),
	SectionHeader = require("@self/SectionHeader"),
	Text = require("@self/Text"),
	Color = require("@self/Color"),
	Toggle = require("@self/Toggle"),
}
-- Hooks
local useCurrentPage =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/useCurrentPage")
-- Contexts
-- Contexts
local CharacterEditorFieldDefinition =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldDefinition")
local IsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/IsHeroFocus")
-- Types
export type Properties = RobloxComponents.FrameProperties & {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local currentPage, path = useCurrentPage()
	local isHeroFocus = React.useContext(IsHeroFocusContext)
	local fields: { [string]: React.ReactNode } = {}
	if currentPage and currentPage.Fields then
		local currentFields: { CharacterEditorFieldDefinition.FieldDefinition } = currentPage.Type == "Default"
				and currentPage.Fields
			or currentPage.Fields
		for i, fieldDef in currentFields do
			local component = FieldComponents[fieldDef.Type]
			if not component then
				warn(`bad component for type "{fieldDef.Type}"`)
				continue
			end
			fields[`{path}-{isHeroFocus}-Field-{i}`] = e(CharacterEditorFieldDefinition.Provider, {
				value = fieldDef,
			}, {
				[`Field-{fieldDef.Type}-{i}`] = e(component, {
					LayoutOrder = i,
				}) :: React.ReactNode,
			})
		end
	end
	return e(RobloxComponents.Frame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
		} :: RobloxComponents.FrameProperties,
		props,
		{
			Title = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json"),
				Size = UDim2.fromScale(1, 0.1),
				Text = "Properties",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			ScrollingFrame = e(
				"ScrollingFrame",
				{
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.5,
					BorderColor3 = Color3.new(1, 1, 1),
					CanvasSize = UDim2.fromScale(0, 1.5),
					Position = UDim2.new(0, 8, 0.1, 8),
					ScrollBarThickness = 15,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					HorizontalScrollBarInset = Enum.ScrollBarInset.Always,
					Size = UDim2.new(1, -16, 0.9, -16),
				} :: RobloxComponents.ScrollingFrameProperties,
				{
					UIPadding = e("UIPadding", {
						PaddingRight = UDim.new(0, 15 + 7),
						PaddingLeft = UDim.new(0, 7),
						PaddingTop = UDim.new(0, 7),
						PaddingBottom = UDim.new(0, 7),
					}),
					UIListLayout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						Padding = UDim.new(0, 14),
						SortOrder = Enum.SortOrder.LayoutOrder,
					}),
					Fields = e(React.Fragment, {}, fields),
				}
			),
		}
	))
end
