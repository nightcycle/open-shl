--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
-- Hooks
-- Contexts
-- Types
export type Properties = RobloxComponents.TextLabelProperties & {
	Currency: PseudoEnum.Currency,
	Balance: number,
}
-- Constants
local TEXT_COLORS: { [PseudoEnum.Currency]: Color3 } = table.freeze({
	Credits = Color3.fromRGB(0, 170, 0),
	Gems = Color3.fromRGB(255, 0, 0),
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	return e(RobloxComponents.TextLabel({
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 2,
		FontFace = Font.new(
			"rbxasset://fonts/families/SourceSansPro.json",
			Enum.FontWeight.Bold,
			Enum.FontStyle.Normal
		),
		Text = `{props.Balance} {ProductDefinition.getCurrencyName(props.Currency)}`,
		TextColor3 = TEXT_COLORS[props.Currency],
		TextScaled = true,
		TextStrokeTransparency = 0,
		TextXAlignment = Enum.TextXAlignment.Right,
	}, props))
end
