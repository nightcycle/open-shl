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
export type Properties = RobloxComponents.BillboardGuiProperties & {
	PersonaName: string,
	UserName: string,
	IsInMenu: boolean, -- the player has a full screen menu open
	-- what they tell about themselves, read in place of the name for as long as it's handed in
	Bio: string?,
	-- the color of the side they're on. left out, the name is in the one of the look
	TeamColor3: Color3?,
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local look = React.useContext(StyleContext).Widgets.NameTag
	local textSize = look.TextSize
	local away = look.Away
	local bioPlacement = look.Bio
	-- a look that has no place for it only ever names
	local bio: string? = if bioPlacement and props.Bio ~= "" then props.Bio else nil
	local textColor3 = props.TeamColor3 or look.TextColor3

	return e(RobloxComponents.BillboardGui(
		{
			ClipsDescendants = false,
			LightInfluence = 0,
			MaxDistance = look.MaxDistance,
			ResetOnSpawn = false, -- it may be mounted in PlayerGui
			Size = UDim2.fromScale(6, 6),
		},
		props,
		{
			PersonaName = e("TextLabel", {
				AnchorPoint = look.Name.AnchorPoint,
				BackgroundTransparency = 1,
				FontFace = look.FontFace,
				Position = look.Name.Position,
				Size = look.Name.Size,
				Text = props.PersonaName ~= "" and props.PersonaName or look.Placeholder or props.UserName,
				TextColor3 = textColor3,
				-- a text without a size of its own fills its box
				TextScaled = if textSize then nil else true,
				TextSize = textSize,
				TextStrokeColor3 = look.TextStrokeColor3,
				TextStrokeTransparency = look.TextStrokeTransparency,
				TextWrapped = if textSize then true else nil,
				-- the two are never read at once
				Visible = if bio then false else nil,
			}),
			Bio = bio and bioPlacement and e("TextLabel", {
				AnchorPoint = bioPlacement.AnchorPoint,
				BackgroundTransparency = 1,
				FontFace = look.FontFace,
				Position = bioPlacement.Position,
				Size = bioPlacement.Size,
				Text = bio,
				TextColor3 = textColor3,
				TextScaled = if textSize then nil else true,
				TextSize = textSize,
				TextStrokeColor3 = look.TextStrokeColor3,
				TextStrokeTransparency = look.TextStrokeTransparency,
				TextWrapped = if textSize then true else nil,
			}),
			AFK = props.IsInMenu and away and e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				FontFace = away.FontFace,
				Position = UDim2.fromScale(0.5, -0.05),
				Size = UDim2.fromScale(2.5, 2.5),
				Text = away.Text,
				TextColor3 = away.TextColor3,
				TextScaled = true,
			}),
		}
	))
end
