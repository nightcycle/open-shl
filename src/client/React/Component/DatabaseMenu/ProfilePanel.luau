--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
-- Hooks
-- Contexts
-- Types
local Types = require("./Types")
export type PublicProfile = Types.PublicProfile
export type Properties = RobloxComponents.FrameProperties & {
	Profile: PublicProfile?,
}
-- Constants
local LABEL_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local VALUE_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local FIELD_HEIGHT = 0.1
local FIELDS = table.freeze({
	{ KEY = "Username", LABEL = "Username:" },
	{ KEY = "Alias", LABEL = "Alias:" },
	{ KEY = "Identity", LABEL = "Identity:" },
	{ KEY = "Alignment", LABEL = "Alignment:" },
})
local NO_PROFILE_TEXT = "Select somebody from the list to read their profile"
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- "LawfulGood" reads as "Lawful Good"
local function getAlignmentText(alignment: PseudoEnum.Alignment): string
	local text = string.gsub(alignment, "(%l)(%u)", "%1 %2")
	return text
end
-- Class
return function(props: Properties)
	local profile = props.Profile
	local values: { [string]: string } = {}
	if profile then
		values.Username = profile.UserName
		values.Alias = profile.AliasName
		values.Identity = profile.IdentityName
		values.Alignment = getAlignmentText(profile.Alignment)
	end

	local fields: { [string]: React.ReactNode } = {}
	for i, FIELD in FIELDS do
		local y = (i - 1) * FIELD_HEIGHT
		fields[`{FIELD.KEY}Label`] = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = LABEL_FONT,
			Position = UDim2.fromScale(0, y),
			Size = UDim2.fromScale(0.35, FIELD_HEIGHT),
			Text = FIELD.LABEL,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Right,
		})
		fields[FIELD.KEY] = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = VALUE_FONT,
			Position = UDim2.fromScale(0.375, y),
			Size = UDim2.fromScale(0.6, FIELD_HEIGHT),
			Text = values[FIELD.KEY] or "",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.2,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
		},
		props,
		{
			Fields = e(React.Fragment, {}, fields),
			Backstory = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = LABEL_FONT,
				Position = UDim2.fromScale(0.05, 0.45),
				Size = UDim2.fromScale(0.9, 0.5),
				Text = profile and profile.Backstory or NO_PROFILE_TEXT,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextTransparency = profile and 0 or 0.5,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextYAlignment = Enum.TextYAlignment.Top,
			}),
		}
	))
end
