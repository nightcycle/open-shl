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
export type Properties = RobloxComponents.TextLabelProperties & {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- whatever holds it says where it goes, it reads from the right edge of that spot
return function(props: Properties)
	return e(RobloxComponents.TextLabel({
		BackgroundTransparency = 1,
		FontFace = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal),
		TextColor3 = Color3.fromRGB(190, 96, 96),
		TextScaled = true,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, props))
end
