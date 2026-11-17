--!strict
--!native
-- Services
local TweenService = game:GetService("TweenService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Components
-- Hooks
-- Contexts
-- Types
export type ActionInfo = {
	Type: "FadedOut",
}
export type Properties = RobloxComponents.FrameProperties & {
	Pun: string,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local LOGO_DELAY = 3
local LOGO_HOLD_DURATION = 3
local FADE_IN_TWEEN_INFO = TweenInfo.new(2, Enum.EasingStyle.Linear)
local FADE_OUT_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Linear)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local logoRef: { current: ImageLabel? } = React.useRef(nil :: ImageLabel?)
	local punRef: { current: TextLabel? } = React.useRef(nil :: TextLabel?)
	local onActionRef = React.useRef(props.OnAction)
	onActionRef.current = props.OnAction
	React.useEffect(function()
		local logo = logoRef.current
		local pun = punRef.current
		if not logo or not pun then
			return function() end
		end
		local logoFadeIn = TweenService:Create(logo, FADE_IN_TWEEN_INFO, {
			ImageTransparency = 0,
		})
		local logoFadeOut = TweenService:Create(logo, FADE_OUT_TWEEN_INFO, {
			ImageTransparency = 1,
		})
		local punFadeOut = TweenService:Create(pun, FADE_OUT_TWEEN_INFO, {
			TextTransparency = 1,
			TextStrokeTransparency = 1,
		})
		local isDead = false
		task.spawn(function()
			task.wait(LOGO_DELAY)
			if isDead then
				return
			end
			logoFadeIn:Play()
			task.wait(FADE_IN_TWEEN_INFO.Time + LOGO_HOLD_DURATION)
			if isDead then
				return
			end
			logoFadeOut:Play()
			punFadeOut:Play()
			task.wait(FADE_OUT_TWEEN_INFO.Time)
			if isDead then
				return
			end
			onActionRef.current({
				Type = "FadedOut",
			})
		end)
		return function()
			isDead = true
			for _, tween in { logoFadeIn, logoFadeOut, punFadeOut } do
				tween:Cancel()
				tween:Destroy()
			end
		end
	end, {})

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Active = false,
		},
		props,
		{
			Logo = e(
				"ImageLabel",
				{
					ref = logoRef,
					BackgroundTransparency = 1,
					ImageContent = Content.fromUri(Image.ui["logo.png"]),
					ImageTransparency = 1,
					Position = UDim2.fromScale(0.2, 0.275),
					Size = UDim2.fromScale(0.6, 0.25),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
				} :: RobloxComponents.ImageLabelProperties
			),

			Pun = e(
				"TextLabel",
				{
					ref = punRef,
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxasset://fonts/families/Balthazar.json"),
					Position = UDim2.fromScale(0, 0.01),
					Size = UDim2.fromScale(1, 0.035),
					Text = props.Pun,
					TextColor3 = Color3.fromRGB(255, 183, 0),
					TextScaled = true,
					TextStrokeTransparency = 0,
					TextWrapped = true,
				} :: RobloxComponents.TextLabelProperties
			),
		}
	))
end
