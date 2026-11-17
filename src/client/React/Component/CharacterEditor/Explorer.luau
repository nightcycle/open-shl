--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local AppearanceItemDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local CharacterEditorUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor")
-- Components
-- Hooks
local useFirstFolderPath =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/useFirstFolderPath")
-- Contexts
local CharacterEditorStateContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/State")
local PathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/Path")
local SetPathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetPath")
-- Types
type PageDefinition = CharacterEditorUtil.PageDefinition
export type Properties = RobloxComponents.FrameProperties & {
	OnBack: () -> (),
	OnExit: () -> (),
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterEditor/CONSTANTS")
-- sized off the width so the canvas can follow the rows
local ROW_HEIGHT = 0.12
local SELECTION_BORDER_SIZE = 5
-- Variables
-- References
-- Private Functions
local e = React.createElement
local function rowButton(props: RobloxComponents.TextButtonProperties & {
	IsSelected: boolean?,
	IsWorn: boolean?,
})
	return e(RobloxComponents.TextButton({
		BackgroundColor3 = props.IsWorn and Color3.fromRGB(0, 170, 0) or Color3.new(),
		BackgroundTransparency = 0.5,
		BorderColor3 = props.IsSelected and CONSTANTS.SELECTION_COLOR or Color3.new(1, 1, 1),
		BorderSizePixel = props.IsSelected and SELECTION_BORDER_SIZE or 1,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
		Modal = true,
		Size = UDim2.fromScale(1, ROW_HEIGHT),
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		TextStrokeColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
		ZIndex = props.IsSelected and 2 or 1,
	}, props))
end
-- Class
return function(props: Properties): React.ReactNode
	local rows: { [string]: React.ReactNode } = {}
	local state = React.useContext(CharacterEditorStateContext)
	local currentPath = React.useContext(PathContext)
	local setCurrentPath = React.useContext(SetPathContext)
	local currentFirstPath = useFirstFolderPath()
	-- back turns into exit right under the pointer, so leaving a draft that was changed takes a second press
	local isDiscarding, setIsDiscarding = React.useState(false)
	React.useEffect(function()
		setIsDiscarding(false)
		return function() end
	end, { state })
	local pages = React.useMemo(function(): { PageDefinition }
		return if state then CharacterEditorUtil.listPages(state) else {}
	end, { state })
	for i, pageDef in pages do
		local pagePath = CharacterEditorDefinition.getChildPath(currentFirstPath, pageDef)
		local text: string
		local isWorn = false
		if pageDef.Type == "Item" then
			local itemDef = AppearanceItemDefinition.get(pageDef.DefinitionId)
			if itemDef.IsErr then
				warn(`item-def err: {itemDef.Value}`)
				continue
			end
			text = itemDef.Value.Name or pageDef.DefinitionId
			isWorn = state ~= nil and CharacterEditorUtil.getIfItemWorn(state, pageDef.DefinitionId)
		else
			text = pageDef.Title or pageDef.Key
		end
		rows[`Field-{i}`] = e(rowButton, {
			LayoutOrder = i,
			Text = text,
			IsSelected = pagePath == currentPath,
			IsWorn = isWorn,
			[React.Event.Activated] = function()
				if not setCurrentPath then
					return
				end
				if pagePath == currentPath then
					setCurrentPath(currentFirstPath)
				else
					setCurrentPath(pagePath)
				end
			end,
		})
	end
	return e(RobloxComponents.Frame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
		} :: RobloxComponents.FrameProperties,
		props,
		{
			UIPadding = e("UIPadding", {
				PaddingRight = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			}),
			ScrollingFrame = e("ScrollingFrame", {
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				CanvasSize = UDim2.new(),
				Position = UDim2.new(0, 8, 0.2, 8),
				ScrollBarThickness = 15,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Size = UDim2.new(1, -16, 0.8, -16),
			}, {
				UIPadding = e("UIPadding", {
					PaddingRight = UDim.new(0, 15 + SELECTION_BORDER_SIZE),
					PaddingLeft = UDim.new(0, SELECTION_BORDER_SIZE),
					PaddingTop = UDim.new(0, SELECTION_BORDER_SIZE),
					PaddingBottom = UDim.new(0, SELECTION_BORDER_SIZE),
				}),
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Vertical,
					Padding = UDim.new(0, 8),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Rows = e(React.Fragment, {}, rows),
			}),

			Title = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json"),
				Size = UDim2.fromScale(1, 0.1),
				Text = "Explorer",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),

			BackButton = e("TextButton", {
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Position = UDim2.fromScale(0.3, 0.125),
				Size = UDim2.fromScale(0.4, 0.075),
				Text = if currentFirstPath ~= "" then "Back" elseif isDiscarding then "Discard Changes?" else "Exit",
				TextColor3 = currentFirstPath == "" and Color3.fromRGB(255, 0, 0) or Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					if currentFirstPath == "" then
						if state and not isDiscarding and CharacterEditorUtil.getIfChanged(state) then
							setIsDiscarding(true)
							return
						end
						props.OnExit()
						return
					end
					if setCurrentPath then
						local parentPath = CharacterEditorDefinition.getParentPath(currentFirstPath)
						if parentPath.IsSome then
							setCurrentPath(CharacterEditorDefinition.findFirstFolderPath(parentPath.Value))
						else
							setCurrentPath("")
						end
						props.OnBack()
					end
				end,
			}),
		}
	))
end
