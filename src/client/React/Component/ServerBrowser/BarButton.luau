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
export type Properties = RobloxComponents.TextButtonProperties & {
	IsConfirm: boolean?, -- green, for the button that takes the player further
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	return e(RobloxComponents.TextButton({
		BackgroundColor3 = if props.IsConfirm then Color3.fromRGB(56, 132, 84) else Color3.fromRGB(48, 48, 48),
		BorderColor3 = if props.IsConfirm then Color3.fromRGB(109, 167, 117) else Color3.fromRGB(76, 76, 76),
		BorderMode = Enum.BorderMode.Inset,
		BorderSizePixel = 3,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Medium, Enum.FontStyle.Normal),
		Size = UDim2.fromOffset(100, 30),
		TextColor3 = if props.IsConfirm then Color3.fromRGB(177, 177, 177) else Color3.fromRGB(127, 127, 127),
		TextScaled = true,
		TextWrapped = true,
	}, props))
end
