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
local Types = require("./Types")
export type PublicProfile = Types.PublicProfile
export type Tab = Types.Tab
export type Properties = RobloxComponents.ScrollingFrameProperties & {
	Profiles: { PublicProfile },
	Tab: Tab,
	SelectedUserId: number?,
	OnClick: (PublicProfile) -> (),
}
-- Constants
local ROW_HEIGHT = 0.09
local ROW_STEP = 0.105
local ROW_OFFSET = 0.015
local SCROLL_BAR_THICKNESS = 12
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	-- how many lists tall the canvas is, the rows are sized against it
	local canvasScale = math.max(1, ROW_OFFSET + #props.Profiles * ROW_STEP)
	local rows: { [string]: React.ReactNode } = {}
	for i, profile in props.Profiles do
		local isSelected = profile.UserId == props.SelectedUserId
		local text = if props.Tab == "Aliases"
			then profile.AliasName
			elseif props.Tab == "Identities" then profile.IdentityName
			else profile.UserName
		rows[`Player-{profile.UserId}`] = e(
			"TextButton",
			{
				BackgroundColor3 = isSelected and Color3.new(1, 1, 1) or Color3.fromRGB(65, 65, 65),
				BackgroundTransparency = 0.6,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0, (ROW_OFFSET + ROW_STEP * (i - 1)) / canvasScale),
				Size = UDim2.new(1, -SCROLL_BAR_THICKNESS - 4, ROW_HEIGHT / canvasScale, 0),
				Text = text,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				[React.Event.Activated] = function()
					props.OnClick(profile)
				end,
			} :: RobloxComponents.TextButtonProperties
		)
	end
	return e(RobloxComponents.ScrollingFrame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.2,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			CanvasSize = UDim2.fromScale(0, canvasScale > 1 and canvasScale or 0),
			ScrollBarThickness = SCROLL_BAR_THICKNESS,
			ScrollingDirection = Enum.ScrollingDirection.Y,
		},
		props,
		{
			Rows = e(React.Fragment, {}, rows),
		}
	))
end
