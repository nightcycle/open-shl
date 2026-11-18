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
export type Properties = RobloxComponents.FrameProperties & {
	Id: string,
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local look = React.useContext(StyleContext).Widgets.ServerId
	local backing = look.Backing
	local textSize = look.TextSize

	return e(RobloxComponents.Frame(
		{
			BackgroundColor3 = if backing then backing.BackgroundColor3 else nil,
			BackgroundTransparency = if backing then nil else 1,
			BorderColor3 = if backing then backing.BorderColor3 else nil,
		},
		props,
		{
			Label = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = look.FontFace,
				Size = UDim2.fromScale(1, 1),
				Text = `ID: {props.Id}`,
				TextColor3 = look.TextColor3,
				-- a text without a size of its own fills its box
				TextScaled = if textSize then nil else true,
				TextSize = textSize,
				TextWrapped = if textSize then nil else true,
				TextXAlignment = look.TextXAlignment,
				TextYAlignment = look.TextYAlignment,
			}),
		}
	))
end
