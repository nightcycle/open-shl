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
-- Types
export type ActionInfo = {
	Type: "Toggle", -- the other mode is asked for
}
export type Properties = RobloxComponents.FrameProperties & {
	-- what the server plays by right now
	IsPVP: boolean,
	OnAction: (ActionInfo) -> (),
}
-- Constants
-- the button names the mode the server is in, not the one a press leads to: the old place had it so
local PVP_TEXT = "PVP Mode"
local ROLEPLAY_TEXT = "RP Mode"
-- on the right edge, a little above the middle of it
local BUTTON_POSITION = UDim2.fromScale(1, 0.43)
-- in pixels, whatever the size of the screen
local BUTTON_SIZE = UDim2.fromOffset(66, 19)
local TEXT_SIZE = 14
-- the one control of the old hud that was never given any art: a box as the engine makes one, its border + its font
-- included
local FONT_FACE = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local BORDER_COLOR3 = Color3.fromRGB(27, 42, 53)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- what the owner of a private server changes its mode with. whoever mounts it says who that is
return function(props: Properties): React.ReactNode
	return e(RobloxComponents.Frame(
		{
			Active = false,
			BackgroundTransparency = 1,
		},
		props,
		{
			Button = e("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderColor3 = BORDER_COLOR3,
				BorderSizePixel = 1,
				FontFace = FONT_FACE,
				Position = BUTTON_POSITION,
				Size = BUTTON_SIZE,
				Text = if props.IsPVP then PVP_TEXT else ROLEPLAY_TEXT,
				TextColor3 = Color3.new(0, 0, 0),
				TextSize = TEXT_SIZE,
				[React.Event.Activated] = function()
					props.OnAction({
						Type = "Toggle",
					})
				end,
			}),
		}
	))
end
