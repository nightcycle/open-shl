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
export type Properties = RobloxComponents.FrameProperties & {
	OnCycle: (direction: number) -> (), -- 1 for the next one to watch, -1 for the one before
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function cycleButton(props: RobloxComponents.TextButtonProperties)
	return e(RobloxComponents.TextButton({
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.new(),
		BorderColor3 = Color3.fromRGB(27, 42, 53),
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
		Size = UDim2.fromOffset(70, 70),
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
	}, props))
end
-- Class
return function(props: Properties)
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			Left = e(
				cycleButton,
				{
					Position = UDim2.fromScale(0, 0.5),
					Text = "<",
					[React.Event.Activated] = function()
						props.OnCycle(-1)
					end,
				} :: RobloxComponents.TextButtonProperties
			),
			Right = e(
				cycleButton,
				{
					Position = UDim2.fromScale(1, 0.5),
					Text = ">",
					[React.Event.Activated] = function()
						props.OnCycle(1)
					end,
				} :: RobloxComponents.TextButtonProperties
			),
		}
	))
end
