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
export type ActionInfo = {
	Type: "NextSlide", -- its screen was pressed
}
export type Properties = RobloxComponents.FrameProperties & {
	-- the picture of the tablet
	FrameImage: string,
	-- what its screen shows, it's dark without
	SlideImage: string?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
-- pixels the old gui was: it's never drawn larger + keeps that shape. the old one hung off a screen that was
-- smaller, this one shrinks to fit it
local MAX_SIZE = Vector2.new(800, 602)
-- of whatever it's given, so it never sits edge to edge
local FIT_SIZE = UDim2.fromScale(0.95, 0.95)
-- where the screen sits in the picture: 618 by 466 at 94, 67 of the 800 by 602
local SCREEN_POSITION = UDim2.fromScale(94 / 800, 67 / 602)
local SCREEN_SIZE = UDim2.fromScale(618 / 800, 466 / 602)
-- a screen with nothing to show is switched off
local DARK_COLOR3 = Color3.new(0, 0, 0)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the screen of the old tablet gear: a picture of a tablet in the middle of everything, with a slide where its
-- screen is. a press on the slide asks for the next, which one that is isn't its to know
return function(props: Properties): React.ReactNode
	return e(RobloxComponents.Frame(
		{
			Active = false,
			BackgroundTransparency = 1,
		},
		props,
		{
			Tablet = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = FIT_SIZE,
			}, {
				UISizeConstraint = e("UISizeConstraint", {
					MaxSize = MAX_SIZE,
				}),
				UIAspectRatioConstraint = e("UIAspectRatioConstraint", {
					AspectRatio = MAX_SIZE.X / MAX_SIZE.Y,
				}),
				ImageFrame = e("ImageLabel", {
					BackgroundTransparency = 1,
					Image = props.FrameImage,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 1,
				}),
				Screen = e("ImageButton", {
					AutoButtonColor = false,
					BackgroundColor3 = DARK_COLOR3,
					BorderSizePixel = 0,
					Image = props.SlideImage or "",
					Position = SCREEN_POSITION,
					Size = SCREEN_SIZE,
					ZIndex = 2,
					[React.Event.Activated] = function()
						props.OnAction({ Type = "NextSlide" })
					end,
				}),
			}),
		}
	))
end
