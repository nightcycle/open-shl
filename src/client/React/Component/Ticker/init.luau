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
	-- what's read out in turn, over + over
	Messages: { string },
}
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- a black bar along the top with one line of news in it. a message is put there whole, read for a while + taken
-- away again: the bar is empty for a moment before the next
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local messages = props.Messages
	-- every message is two steps, the empty bar before it + the message itself
	local step: number, setStep: (number) -> () = React.useState(0)
	local isShown = step % 2 == 1

	React.useEffect(function()
		if #messages == 0 then
			return function() end
		end
		local isDead = false
		task.delay(if isShown then CONSTANTS.HOLD_DURATION else CONSTANTS.GAP_DURATION, function()
			if not isDead then
				setStep(step + 1)
			end
		end)
		return function()
			isDead = true
		end
	end, { step :: any, #messages })

	local message: string? = if isShown then messages[(step - 1) // 2 % #messages + 1] else nil
	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Active = false,
		},
		props,
		{
			Bar = e("Frame", {
				BackgroundColor3 = CONSTANTS.BAR_COLOR,
				-- the edge the engine gives a box was never taken off it
				BorderColor3 = style.Border.Color3,
				BorderSizePixel = style.Border.SizePixel,
				Size = CONSTANTS.BAR_SIZE,
			}, {
				Message = if message
					then e("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = style.Fonts.Body,
						Size = UDim2.fromScale(1, 1),
						Text = message,
						TextColor3 = style.Palette.Text,
						TextScaled = true,
						TextWrapped = true,
					})
					else nil,
			}),
		}
	))
end
