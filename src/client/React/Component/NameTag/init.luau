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
export type Properties = RobloxComponents.BillboardGuiProperties & {
	PersonaName: string,
	UserName: string,
	IsInMenu: boolean, -- the player has a full screen menu open
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	return e(RobloxComponents.BillboardGui(
		{
			ClipsDescendants = false,
			LightInfluence = 0,
			ResetOnSpawn = false, -- it may be mounted in PlayerGui
			Size = UDim2.fromScale(6, 6),
		},
		props,
		{
			PersonaName = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0, 0.135),
				Size = UDim2.fromScale(1, 0.15),
				Text = props.PersonaName ~= "" and props.PersonaName or props.UserName,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeTransparency = 0,
			}),
			AFK = props.IsInMenu and e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/Arial.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(0.5, -0.05),
				Size = UDim2.fromScale(2.5, 2.5),
				Text = "AFK",
				TextColor3 = Color3.fromRGB(223, 60, 60),
				TextScaled = true,
			}),
		}
	))
end
