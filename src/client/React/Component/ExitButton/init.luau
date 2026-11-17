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
export type Properties = RobloxComponents.ImageButtonProperties & {}
-- Constants
local ICON_URL = "rbxassetid://1373549749"
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	return e(RobloxComponents.ImageButton({
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ImageContent = Content.fromUri(ICON_URL),
		Size = UDim2.fromOffset(40, 40),
	}, props))
end
