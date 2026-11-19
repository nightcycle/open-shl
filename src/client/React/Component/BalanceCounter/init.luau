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
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
export type Properties = RobloxComponents.TextLabelProperties & {
	Currency: PseudoEnum.Currency,
	Balance: number,
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local style = React.useContext(StyleContext)
	local look = style.Widgets.BalanceCounter
	local prefix = look.Prefix

	return e(RobloxComponents.TextLabel({
		BackgroundColor3 = look.BackgroundColor3,
		BackgroundTransparency = look.BackgroundTransparency,
		BorderColor3 = look.BorderColor3,
		BorderSizePixel = look.BorderSizePixel,
		FontFace = look.FontFace or style.Fonts.Heading,
		-- a look that says what the number is before it has no use for the name of the currency after it
		Text = if prefix
			then `{prefix}{props.Balance}`
			else `{props.Balance} {ProductDefinition.getCurrencyName(props.Currency)}`,
		TextColor3 = look.TextColors[props.Currency],
		TextScaled = true,
		TextStrokeTransparency = look.TextStrokeTransparency,
		TextXAlignment = look.TextXAlignment,
	}, props))
end
