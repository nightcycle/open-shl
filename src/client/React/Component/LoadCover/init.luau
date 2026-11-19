--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Components
-- Hooks
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local LoadingScreenTypes =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/LoadingScreen/Types")
export type ActionInfo = LoadingScreenTypes.ActionInfo
export type Properties = LoadingScreenTypes.Properties
-- Constants
local LOGO_URL = Image["shl-1"].ui["load-screen-logo.png"]
local COVER_COLOR = Color3.new()
-- the cover is two screens tall + starts a screen above the top, so it's black behind the top bar as well. what's on
-- it is placed in scale of all of that: the logo ends up in the upper half of the screen, a little taller than wide
local COVER_POSITION = UDim2.fromScale(0, -1)
local COVER_SIZE = UDim2.fromScale(1, 2)
local LOGO_POSITION = UDim2.fromScale(0.4, 0.6)
local LOGO_SIZE = UDim2.fromScale(0.2, 0.2)
local LABEL_POSITION = UDim2.fromScale(0.3, 0.85)
local LABEL_SIZE = UDim2.fromScale(0.4, 0.1)
local LABEL_TEXT = "LOADING"
-- the logo isn't spun, it's put a step further round ten times a second
local TURN_INTERVAL = 0.1
local TURN_STEP = 20
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- a black screen with the logo of the studio turning on it + one word under it. it has no bar: how far the load is
-- isn't said, and there's nothing to skip
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local turnCount, setTurnCount = React.useState(0)

	React.useEffect(function()
		local isDead = false
		task.spawn(function()
			local count = 0
			while true do
				task.wait(TURN_INTERVAL)
				if isDead then
					return
				end
				count += 1
				setTurnCount(count)
			end
		end)
		return function()
			isDead = true
		end
	end, {})

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			Cover = e(
				"Frame",
				{
					Active = true,
					BackgroundColor3 = COVER_COLOR,
					BorderSizePixel = 0,
					Position = COVER_POSITION,
					Size = COVER_SIZE,
				} :: RobloxComponents.FrameProperties,
				{
					Logo = e(
						"ImageLabel",
						{
							BackgroundTransparency = 1,
							ImageContent = Content.fromUri(LOGO_URL),
							Position = LOGO_POSITION,
							Rotation = turnCount * TURN_STEP,
							Size = LOGO_SIZE,
						} :: RobloxComponents.ImageLabelProperties
					),

					Load = e("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = style.Fonts.Body,
						Position = LABEL_POSITION,
						Size = LABEL_SIZE,
						Text = LABEL_TEXT,
						TextColor3 = style.Palette.Text,
						TextScaled = true,
						TextWrapped = true,
					}),
				}
			),
		}
	))
end
