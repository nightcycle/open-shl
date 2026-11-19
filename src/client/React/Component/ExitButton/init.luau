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
return function(props: Properties): React.ReactNode
	local look = React.useContext(StyleContext).Widgets.ExitButton
	local tint, listeners = useButtonTint(
		if look.Type == "Image" then look.Hover else nil,
		if look.Type == "Image" then look.Press else nil
	)

	-- a game without a picture for it says it in a word, on a box of the size the picture would be pressed at
	if look.Type == "Text" then
		local label: RobloxComponents.TextButtonProperties = {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = look.BackgroundColor3,
			BorderColor3 = look.BorderColor3,
			BorderSizePixel = look.BorderSizePixel,
			FontFace = look.FontFace,
			Size = look.Size,
			Text = look.Text,
			TextColor3 = look.TextColor3,
			TextScaled = true,
			TextWrapped = true,
		}
		return e(RobloxComponents.TextButton(label, props :: any))
	end

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
