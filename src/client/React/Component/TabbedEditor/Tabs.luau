--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
-- Hooks
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local Types = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/TabbedEditor/Types")
type TabInfo = Types.TabInfo
export type Properties = RobloxComponents.FrameProperties & {
	Tabs: { TabInfo },
	SelectedKey: string?,
	OnSelect: (tab: TabInfo) -> (),
	OnDone: () -> (),
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/TabbedEditor/CONSTANTS")
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- a square picture, its caption hangs off its left side
local function tabButton(props: {
	LayoutOrder: number,
	Icon: string,
	Caption: string,
	IsSelected: boolean,
	OnClick: () -> (),
})
	local style = React.useContext(StyleContext)
	return e("ImageButton", {
		BackgroundTransparency = 1,
		Image = props.Icon,
		ImageColor3 = if props.IsSelected then style.Palette.Accent else Color3.new(1, 1, 1),
		LayoutOrder = props.LayoutOrder,
		Size = UDim2.fromScale(CONSTANTS.TAB_SIZE, CONSTANTS.TAB_SIZE),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		[React.Event.Activated] = props.OnClick,
	}, {
		Caption = e("TextLabel", {
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Heading,
			Position = CONSTANTS.TAB_CAPTION_POSITION,
			Size = CONSTANTS.TAB_CAPTION_SIZE,
			Text = props.Caption,
			TextColor3 = style.Palette.Accent,
			TextSize = CONSTANTS.TAB_CAPTION_TEXT_SIZE,
			TextXAlignment = Enum.TextXAlignment.Right,
		}),
	})
end
-- Class
-- the column of pages down the right edge, the one that's open is tinted
return function(props: Properties): React.ReactNode
	local buttons: { [string]: React.ReactNode } = {}
	for index, tab in props.Tabs do
		buttons[`Tab-{tab.Key}`] = e(tabButton, {
			LayoutOrder = index,
			Icon = tab.Icon,
			Caption = tab.Caption,
			IsSelected = tab.Key == props.SelectedKey,
			OnClick = function()
				props.OnSelect(tab)
			end,
		})
	end
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		} :: RobloxComponents.FrameProperties,
		props,
		{
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(CONSTANTS.TAB_PADDING, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),
			Buttons = e(React.Fragment, {}, buttons),
			Done = e(tabButton, {
				LayoutOrder = #props.Tabs + 1,
				Icon = CONSTANTS.DONE_ICON,
				Caption = CONSTANTS.DONE_CAPTION,
				IsSelected = false,
				OnClick = props.OnDone,
			}),
		}
	))
end
