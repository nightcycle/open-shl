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
export type ActionInfo = {
	Type: "ToggleMute",
}
export type Properties = RobloxComponents.FrameProperties & {
	-- what was said, the newest last: rich text, a line each. the last few of them are read
	Lines: { string },
	-- whoever reads it sits fights out
	IsPeaceful: boolean,
	IsMuting: boolean,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the chat of the first game: the last dozen lines in white on nothing in the top left, with one button under them
-- that keeps the players of the other mode quiet. nothing of it moves, a line is put a row higher with every new one
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local lines = props.Lines

	local labels: { [string]: React.ReactNode } = {}
	for row = 1, math.min(#lines, CONSTANTS.LINE_COUNT) do
		-- the first row is the newest
		labels[`Line{row}`] = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Note,
			Position = UDim2.new(0, 0, 1, -row * CONSTANTS.LINE_HEIGHT),
			RichText = true,
			Size = UDim2.new(1, 0, 0, CONSTANTS.LINE_HEIGHT),
			Text = lines[#lines - row + 1],
			TextColor3 = style.Palette.Text,
			TextSize = style.TextSizes.Note,
			TextStrokeColor3 = CONSTANTS.LINE_STROKE_COLOR,
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		})
	end
	labels.Mute = e("TextButton", {
		BackgroundColor3 = CONSTANTS.MUTE_COLOR,
		-- the edge + the text the engine gives a button were never taken off it
		BorderColor3 = style.Border.Color3,
		BorderSizePixel = style.Border.SizePixel,
		FontFace = style.Fonts.Body,
		Position = CONSTANTS.MUTE_POSITION,
		Size = CONSTANTS.MUTE_SIZE,
		Text = if props.IsMuting
			then CONSTANTS.MUTED_TEXT
			elseif props.IsPeaceful then CONSTANTS.MUTE_FIGHTING_TEXT
			else CONSTANTS.MUTE_PEACEFUL_TEXT,
		TextColor3 = style.Border.Color3,
		TextScaled = true,
		TextWrapped = true,
		-- it took the press as it went down
		[React.Event.MouseButton1Down] = function()
			props.OnAction({
				Type = "ToggleMute",
			})
		end,
	})

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Active = false,
		},
		props,
		{
			Log = e("Frame", {
				BackgroundTransparency = 1,
				Position = CONSTANTS.LOG_POSITION,
				Size = CONSTANTS.LOG_SIZE,
			}, labels),
		}
	))
end
