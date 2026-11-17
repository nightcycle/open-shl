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
local BuildTypes = require("./Types")
type ThemeDefinition = BuildTypes.ThemeDefinition
export type Properties = RobloxComponents.FrameProperties & {
	ThemeDefinition: ThemeDefinition,
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/BuildMenu/CONSTANTS")
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local stripes: { [string]: React.ReactNode } = {}
	for i, swatchInfo in CONSTANTS.SWATCHES do
		local surface = props.ThemeDefinition.Palette[swatchInfo.PaletteKey]
		if not surface then
			warn(`theme "{props.ThemeDefinition.Id}" has no "{swatchInfo.PaletteKey}"`)
			continue
		end
		stripes[swatchInfo.Name] = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundColor3 = surface.Color,
			BorderSizePixel = 0,
			Position = UDim2.fromScale(0.5, (i - 1) / #CONSTANTS.SWATCHES),
			Size = UDim2.fromScale(1, 1 / #CONSTANTS.SWATCHES),
		})
	end
	return e(RobloxComponents.Frame(
		{
			BackgroundColor3 = Color3.fromRGB(141, 141, 141),
			BorderSizePixel = 0,
		},
		props,
		{
			Stripes = e(React.Fragment, {}, stripes),
		}
	))
end
