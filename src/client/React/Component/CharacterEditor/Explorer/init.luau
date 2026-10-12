--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
local TextButton = require("@game/ReplicatedStorage/Generated/React/Component/TextButton")
-- Hooks
local useCurrentPage =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/useCurrentPage")
-- Contexts
local IsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/IsHeroFocus")
-- Types
export type Properties = Frame.Properties & {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
function rowButton(props: TextButton.Properties)
	return e(TextButton({
		BackgroundColor3 = Color3.new(),
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
	local currentPage = useCurrentPage()
	local rows: { [string]: React.ReactNode } = {}
	local isHeroFocus = React.useContext(IsHeroFocusContext)
	if currentPage and currentPage.Type == "Default" and currentPage.Children then
		for i, pageDef in currentPage.Children do
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
				rows[`Field-{i}`] = e(rowButton, {
					LayoutOrder = i,
					Text = pageDef.DefinitionId,
				})
			elseif pageDef.Type == "Default" then
				rows[`Field-{i}`] = e(rowButton, {
					LayoutOrder = i,
					Text = pageDef.Title or pageDef.Key,
				})
			end
		end
	end
	print(`page`, currentPage)
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
				Text = "Exit",
				TextColor3 = Color3.fromRGB(255, 0, 0),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
			}),
		}
	))
end
