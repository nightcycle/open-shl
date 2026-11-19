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
	Text: string,
	LeftPosition: UDim2,
	RightPosition: UDim2,
	ArrowSize: UDim2,
	NamePosition: UDim2,
	NameSize: UDim2,
	OnStep: ((direction: number) -> ())?, -- left out, the row is only looked at
	OnName: (() -> ())?, -- left out, what the row is called isn't pressed
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- a bar with an arrow at each end + what it steps through written between them. the arrows have no box of their own,
-- so nothing shows where one is pressed. the bar says what it's a row of, never which one of them is picked
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local onStep, onName = props.OnStep, props.OnName

	local function arrow(text: string, position: UDim2, direction: number): React.ReactNode
		return e("TextButton", {
			Active = onStep ~= nil,
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Body,
			Position = position,
			Size = props.ArrowSize,
			Text = text,
			TextColor3 = style.Palette.Text,
			TextScaled = true,
			TextWrapped = true,
			[React.Event.Activated] = if onStep
				then function()
					onStep(direction)
				end
				else nil,
		})
	end

	return e(RobloxComponents.Frame(
		{
			-- the blue of a field unless whoever mounts it has another bar for it
			BackgroundColor3 = if props.BackgroundColor3 == nil then style.Palette.Field else nil,
			BorderSizePixel = 0,
		},
		props,
		{
			Left = arrow("<", props.LeftPosition, -1),
			Right = arrow(">", props.RightPosition, 1),
			Name = e("TextButton", {
				Active = onName ~= nil,
				BackgroundTransparency = 1,
				FontFace = style.Fonts.Body,
				Position = props.NamePosition,
				Size = props.NameSize,
				Text = props.Text,
				TextColor3 = style.Palette.Text,
				TextScaled = true,
				TextWrapped = true,
				[React.Event.Activated] = onName,
			}),
		}
	))
end
