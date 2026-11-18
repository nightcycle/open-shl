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

	return e(RobloxComponents.TextLabel({
		BackgroundColor3 = look.BackgroundColor3,
		BorderColor3 = look.BorderColor3,
		BorderSizePixel = look.BorderSizePixel,
		FontFace = style.Fonts.Heading,
		Text = `{props.Balance} {ProductDefinition.getCurrencyName(props.Currency)}`,
		TextColor3 = look.TextColors[props.Currency],
		TextScaled = true,
		TextStrokeTransparency = look.TextStrokeTransparency,
		TextXAlignment = look.TextXAlignment,
	}, props))
end
