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
	Colors: { Color3 }, -- what each swatch is drawn in, row by row
	ColumnCount: number,
	OnPick: ((index: number) -> ())?, -- left out, the grid is only looked at
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- a white box filled with swatches edge to edge, as many rows as its columns: each has the thin dark edge of the look,
-- which is all that draws the lines between them. none of them is marked as the one that's picked
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local border = style.Border
	local onPick = props.OnPick
	local cellScale = 1 / props.ColumnCount

	local swatches: { [string]: React.ReactNode } = {}
	for index, color in props.Colors do
		local column = (index - 1) % props.ColumnCount
		local row = (index - 1) // props.ColumnCount
		swatches[`Swatch-{index}`] = e("TextButton", {
			Active = onPick ~= nil,
			BackgroundColor3 = color,
			BorderColor3 = border.Color3,
			BorderSizePixel = border.SizePixel,
			Position = UDim2.fromScale(column * cellScale, row * cellScale),
			Size = UDim2.fromScale(cellScale, cellScale),
			Text = "",
			[React.Event.Activated] = if onPick
				then function()
					onPick(index)
				end
				else nil,
		})
	end

	return e(RobloxComponents.Frame({
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderColor3 = border.Color3,
		BorderSizePixel = border.SizePixel,
	}, props, swatches))
end
