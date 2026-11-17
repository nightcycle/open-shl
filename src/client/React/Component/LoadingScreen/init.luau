--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
-- Hooks
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Contexts
-- Types
export type Properties = RobloxComponents.FrameProperties & {
	Progress: number, -- from 0 to 1
}
-- Constants
local LOGO_URL = "rbxassetid://1470835910"
local PROMO_TEXT = "Join Deadly Pineapple Games for free gems!"
local MIN_FILL = 0.01
local FILL_TWEEN_INFO = TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local fill = math.clamp(props.Progress, MIN_FILL, 1)
	local fillRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local initialFillRef = React.useRef(fill)
	useTween(fillRef, FILL_TWEEN_INFO, {
		Size = UDim2.fromScale(fill, 1),
	}, { fill })

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			-- covers the top bar inset
			Backdrop = e("Frame", {
				Active = true,
				BackgroundColor3 = Color3.new(),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, -1),
				Size = UDim2.fromScale(1, 2),
			}),

			Logo = e("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ImageContent = Content.fromUri(LOGO_URL),
				Position = UDim2.fromScale(0.5, 0.3),
				Size = UDim2.fromScale(0.6, 0.6),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				ZIndex = 2,
			}),

			FillBar = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.new(),
				BorderColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 3,
				Position = UDim2.fromScale(0.5, 0.66),
				Size = UDim2.new(0.8, 0, 0, 30),
				ZIndex = 2,
			}, {
				Fill = e(
					"Frame",
					{
						ref = fillRef,
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = Color3.new(1, 1, 1),
						BorderSizePixel = 0,
						Position = UDim2.fromScale(0, 0.5),
						Size = UDim2.fromScale(initialFillRef.current, 1),
					} :: RobloxComponents.FrameProperties
				),
			}),

			Promo = e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new(
					"rbxasset://fonts/families/SourceSansPro.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				Position = UDim2.fromScale(0.5, 0.8),
				Size = UDim2.fromScale(0.7, 0.09),
				Text = PROMO_TEXT,
				TextColor3 = Color3.fromRGB(255, 217, 0),
				TextScaled = true,
				TextWrapped = true,
				ZIndex = 2,
			}),
		}
	))
end
