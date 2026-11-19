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
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
export type ActionInfo = {
	Type: "FadedOut",
}
export type Properties = RobloxComponents.FrameProperties & {
	-- how many seconds the flight behind it takes, the logo comes + goes by it. the screen stays blank until it's known
	Duration: number?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local LOGO_URL = Image["shl-3"].ui.intro["logo.png"]
-- every screen before it ends on a blank one, this is how that clears off the city
local CLEAR_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Linear)
-- the logo takes this much of the flight to come + as much of its end to go
local FADE_SHARE = 0.25
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the logo of the game over the city the camera flies in on
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local backdropRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local logoRef: { current: ImageLabel? } = React.useRef(nil :: ImageLabel?)
	local onActionRef = React.useRef(props.OnAction)
	onActionRef.current = props.OnAction
	local duration = props.Duration
	React.useEffect(function()
		local backdrop = backdropRef.current
		local logo = logoRef.current
		if not duration or not backdrop or not logo then
			return function() end
		end
		local fadeTweenInfo = TweenInfo.new(duration * FADE_SHARE, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
		local clear = TweenService:Create(backdrop, CLEAR_TWEEN_INFO, {
			BackgroundTransparency = 1,
		})
		local logoFadeIn = TweenService:Create(logo, fadeTweenInfo, {
			ImageTransparency = 0,
		})
		local logoFadeOut = TweenService:Create(logo, fadeTweenInfo, {
			ImageTransparency = 1,
		})
		local isDead = false
		task.spawn(function()
			clear:Play()
			logoFadeIn:Play()
			task.wait(duration * (1 - FADE_SHARE))
			if isDead then
				return
			end
			logoFadeOut:Play()
			task.wait(duration * FADE_SHARE)
			if isDead then
				return
			end
			onActionRef.current({
				Type = "FadedOut",
			})
		end)
		return function()
			isDead = true
			for _, tween in { clear, logoFadeIn, logoFadeOut } do
				tween:Cancel()
				tween:Destroy()
			end
		end
	end, { duration })

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Active = false,
		},
		props,
		{
			-- covers the top bar inset
			Backdrop = e(
				"Frame",
				{
					ref = backdropRef,
					BackgroundColor3 = style.Palette.Field,
					BackgroundTransparency = 0,
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0, -1),
					Size = UDim2.fromScale(1, 2),
				} :: RobloxComponents.FrameProperties
			),

			Logo = e(
				"ImageLabel",
				{
					ref = logoRef,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					ImageContent = Content.fromUri(LOGO_URL),
					ImageTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 0.565),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					ZIndex = 2,
				} :: RobloxComponents.ImageLabelProperties
			),
		}
	))
end
