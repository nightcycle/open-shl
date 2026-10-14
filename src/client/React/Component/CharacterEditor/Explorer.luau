--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AppearanceItemDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
-- Components
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
local TextButton = require("@game/ReplicatedStorage/Generated/React/Component/TextButton")
-- Hooks
local useFirstFolderPath =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/useFirstFolderPath")
local usePage = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/usePage")
-- Contexts
local IsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/IsHeroFocus")
local PathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/Path")
local SetPathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetPath")
-- Types
export type Properties = Frame.Properties & {
	OnExit: () -> (),
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
function rowButton(props: TextButton.Properties & {
	IsSelected: boolean?,
})
	return e(TextButton({
		BackgroundColor3 = props.IsSelected and Color3.fromRGB(0, 170, 0) or Color3.new(),
		BackgroundTransparency = 0.5,
		BorderColor3 = Color3.new(1, 1, 1),
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
		Modal = true,
		Size = UDim2.new(1, -15, 0.0375, 0),
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		TextStrokeColor3 = Color3.new(1, 1, 1),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, props))
end
-- Class
return function(props: Properties): React.ReactNode
	local rows: { [string]: React.ReactNode } = {}
	local isHeroFocus = React.useContext(IsHeroFocusContext)
	local currentPath = React.useContext(PathContext)
	local setCurrentPath = React.useContext(SetPathContext)
	local currentFirstPath = useFirstFolderPath()
	local currentFirstPage = usePage(currentFirstPath)
	if currentFirstPage and currentFirstPage.Type == "Default" and currentFirstPage.Children then
		for i, pageDef in currentFirstPage.Children do
			local pagePath = CharacterEditorDefinition.getChildPath(currentFirstPath, pageDef)
			local function navigateTo()
				if not setCurrentPath then
					return
				end
				if pagePath == currentPath then
					setCurrentPath(currentFirstPath)
				else
					setCurrentPath(pagePath)
				end
			end
			if pageDef.ExclusionTags then
				if isHeroFocus then
					if table.find(pageDef.ExclusionTags, "IsSuper") then
						continue
					end
				else
					if table.find(pageDef.ExclusionTags, "IsSecret") then
						continue
					end
				end
			end
			if pageDef.Type == "Item" then
				local itemDef = AppearanceItemDefinition.get(pageDef.DefinitionId)
				if itemDef.IsErr then
					warn(`item-def err: {itemDef.Value}`)
					continue
				end
				rows[`Field-{i}`] = e(rowButton, {
					LayoutOrder = i,
					Text = itemDef.Value.Name,
					IsSelected = pagePath == currentPath,
					[React.Event.Activated] = function(rbx: GuiObject)
						navigateTo()
					end,
				})
			elseif pageDef.Type == "Default" then
				rows[`Field-{i}`] = e(rowButton, {
					LayoutOrder = i,
					Text = pageDef.Title or pageDef.Key,
					IsSelected = pagePath == currentPath,
					[React.Event.Activated] = function()
						navigateTo()
					end,
				})
			end
		end
	end
	return e(Frame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
		} :: Frame.Properties,
		props,
		{
			UIPadding = e("UIPadding", {
				PaddingRight = UDim.new(0, 8),
				PaddingLeft = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 8),
				PaddingBottom = UDim.new(0, 8),
			}),
			ScrollingFrame = e("ScrollingFrame", {
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(1, 1, 1),
				Position = UDim2.new(0, 8, 0.2, 8),
				ScrollBarThickness = 15,
				ScrollingDirection = Enum.ScrollingDirection.Y,
				Size = UDim2.new(1, -16, 0.8, -16),
			}, {

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
				Text = currentFirstPath == "" and "Exit" or "Back",
				TextColor3 = currentFirstPath == "" and Color3.fromRGB(255, 0, 0) or Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					if currentFirstPath == "" then
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
						return
					end
				end,
			}),
		}
	))
end
