--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local CharacterEditorUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor")
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
-- Contexts
local CharacterEditorFieldDefinition =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldDefinition")
local CharacterEditorRefusalContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/Refusal")
local CharacterEditorStateContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/State")
local IsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/IsHeroFocus")
local PathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/Path")
local PickerPowerIdContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/PickerPowerId")
local SetPickerPowerIdContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetPickerPowerId")
-- Types
type FieldDefinition = CharacterEditorFieldDefinition.FieldDefinition
export type Properties = RobloxComponents.FrameProperties & {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local state = React.useContext(CharacterEditorStateContext)
	local path = React.useContext(PathContext)
	local isHeroFocus = React.useContext(IsHeroFocusContext)
	local refusal = React.useContext(CharacterEditorRefusalContext)
	local scrollingFrameRef: { current: ScrollingFrame? } = React.useRef(nil :: ScrollingFrame?)
	local pickerPowerId: string?, setPickerPowerId: (string?) -> () = React.useState(nil :: string?)
	local currentFields = React.useMemo(function(): { FieldDefinition }
		return if state then CharacterEditorUtil.listFields(state) else {}
	end, { state })

	-- every page opens at its top with no color picker left open
	React.useEffect(function()
		setPickerPowerId(nil)
		local scrollingFrame = scrollingFrameRef.current
		if scrollingFrame then
			scrollingFrame.CanvasPosition = Vector2.zero
		end
		return function() end
	end, { path :: any, isHeroFocus })
	React.useEffect(function()
		local scrollingFrame = scrollingFrameRef.current
		if scrollingFrame and refusal and refusal.Field.Type == "ChoiceList" then
			scrollingFrame.CanvasPosition = Vector2.zero
		end
		return function() end
	end, { refusal })

	local fields: { [string]: React.ReactNode } = {}
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
	return e(RobloxComponents.Frame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Visible = path ~= "",
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
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.5,
					BorderColor3 = Color3.new(1, 1, 1),
					CanvasSize = UDim2.new(),
					Position = UDim2.new(0, 8, 0.1, 8),
					ref = scrollingFrameRef,
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
					PickerPowerId = e(PickerPowerIdContext.Provider, {
						value = pickerPowerId,
					}, {
						SetPickerPowerId = e(SetPickerPowerIdContext.Provider, {
							value = setPickerPowerId,
						}, {
							Fields = e(React.Fragment, {}, fields),
						}),
					}),
				}
			),
		}
	))
end
