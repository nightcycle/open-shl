--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
-- Hooks
local useButtonTint = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useButtonTint")
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
export type Properties = RobloxComponents.ImageButtonProperties & {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local look = React.useContext(StyleContext).Widgets.ExitButton
	local tint, listeners = useButtonTint(look.Hover, look.Press)

	local own: RobloxComponents.ImageButtonProperties = {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = if tint then tint.BackgroundColor3 else nil,
		BackgroundTransparency = if tint and tint.BackgroundTransparency then tint.BackgroundTransparency else 1,
		BorderSizePixel = 0,
		ImageColor3 = if tint then tint.ImageColor3 else nil,
		ImageContent = Content.fromUri(look.Image),
		ImageTransparency = if tint then tint.ImageTransparency else nil,
		Size = look.Size,
	}
	for event, listener in listeners do
		(own :: { [any]: any })[event] = listener
	end
	return e(RobloxComponents.ImageButton(own, props))
end
