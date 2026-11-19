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
local ShopMenuTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ShopMenu/Types")
export type ActionInfo = ShopMenuTypes.ActionInfo
-- one product + what its row says of it: what's paid + what's had for it
export type RowInfo = {
	ProductId: string,
	Text: string,
}
export type Properties = RobloxComponents.FrameProperties & {
	-- top to bottom, the panel has room for six
	Rows: { RowInfo },
	ErrorMessage: string?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the shop of the first game: a panel the engine draws with a row for every lot of cash. it has no way out of its
-- own, the button it was opened with shuts it again
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local palette = style.Palette
	local panel = style.Panel
	local errorMessage = props.ErrorMessage
	-- the row that was pressed last. it's where what went wrong is said: this game says things on what was pressed
	local pressedId: string?, setPressedId: (string?) -> () = React.useState(nil :: string?)
	assert(#props.Rows <= CONSTANTS.MAX_ROWS, `the panel has room for {CONSTANTS.MAX_ROWS} rows, not {#props.Rows}`)

	-- an error nobody pressed anything for is said on the first row
	local errorIndex = 1
	for index, rowInfo in props.Rows do
		if rowInfo.ProductId == pressedId then
			errorIndex = index
		end
	end

	local rows: { [string]: React.ReactNode } = {}
	for index, rowInfo in props.Rows do
		local isError = errorMessage ~= nil and index == errorIndex
		rows[`Row-{rowInfo.ProductId}`] = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0, (index - 1) * CONSTANTS.ROW_STEP),
			Size = CONSTANTS.ROW_SIZE,
			ZIndex = 2,
		}, {
			Label = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = style.Fonts.Heading,
				Size = CONSTANTS.LABEL_SIZE,
				Text = if isError and errorMessage then errorMessage else rowInfo.Text,
				TextColor3 = if isError then palette.Negative else palette.Text,
				TextScaled = true,
				TextWrapped = true,
			}),
			Button = e("TextButton", {
				BackgroundColor3 = CONSTANTS.BUTTON_COLOR,
				BorderSizePixel = 0,
				FontFace = style.Fonts.Body,
				Position = CONSTANTS.BUTTON_POSITION,
				Size = CONSTANTS.BUTTON_SIZE,
				Text = CONSTANTS.BUTTON_TEXT,
				TextColor3 = CONSTANTS.BUTTON_TEXT_COLOR,
				TextScaled = true,
				TextWrapped = true,
				[React.Event.Activated] = function()
					setPressedId(rowInfo.ProductId)
					props.OnAction({
						Type = "Purchase",
						ProductId = rowInfo.ProductId,
					})
				end,
			}),
		})
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			-- the panel of the look fills the box. a look that leaves it to the engine has no color to give it
			Panel = if panel.Type == "Engine"
				then e("Frame", {
					Size = UDim2.fromScale(1, 1),
					Style = panel.Style,
				})
				elseif panel.Type == "Image" then e("ImageLabel", {
					BackgroundTransparency = 1,
					ImageColor3 = panel.ImageColor3,
					ImageContent = Content.fromUri(panel.Image),
					ScaleType = panel.ScaleType,
					SliceCenter = panel.SliceCenter,
					Size = UDim2.fromScale(1, 1),
				})
				else e("Frame", {
					BackgroundColor3 = panel.BackgroundColor3,
					BackgroundTransparency = panel.BackgroundTransparency,
					BorderColor3 = panel.BorderColor3,
					BorderSizePixel = panel.BorderSizePixel,
					Size = UDim2.fromScale(1, 1),
				}),
			Rows = e(React.Fragment, {}, rows),
		}
	))
end
