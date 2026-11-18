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
	Id: string,
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	return e(RobloxComponents.Frame(
		{
			BackgroundColor3 = Color3.new(),
			BorderColor3 = Color3.fromRGB(27, 42, 53),
		},
		props,
		{
			Label = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/ComicNeueAngular.json"),
				Size = UDim2.fromScale(1, 1),
				Text = `ID: {props.Id}`,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextWrapped = true,
			}),
		}
	))
end
