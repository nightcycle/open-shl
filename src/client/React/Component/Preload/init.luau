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
local LoadingScreenTypes =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/LoadingScreen/Types")
export type ActionInfo = LoadingScreenTypes.ActionInfo
export type Properties = LoadingScreenTypes.Properties
-- Constants
local LOGO_URL = Image.shl3.ui.intro["studio-logo.png"]
local SPACE_URL = Image.shl3.ui.intro["studio-logo-space.png"]
-- the stars behind the logo are a picture this many times its size, for a minute it drifts up + to the left
local SPACE_SIZE = 2.5
local SPACE_AWAY_POSITION = UDim2.fromScale(-1.5, -0.5)
local SPACE_TWEEN_INFO = TweenInfo.new(60, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
-- how much of each edge of the logo is covered, the stars aren't to show around its picture
local MASK_INSET = 0.05
-- the screen comes out of a blank one + goes back into one
local FADE_IN_TWEEN_INFO = TweenInfo.new(2, Enum.EasingStyle.Linear)
local FADE_OUT_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Linear)
-- the bar waits below the screen until the logo had it to itself for this long
local BAR_DELAY = 3
local BAR_POSITION = UDim2.fromScale(0.5, 0.719)
local BAR_AWAY_POSITION = UDim2.fromScale(0.5, 1.419)
local BAR_IN_TWEEN_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local BAR_OUT_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- how long a load that's over is left standing before all of it goes
local LEAVE_DELAY = 0.8
-- pixels between the edge of the bar + what fills it
local FILL_INSET = 5
local MIN_PERCENT = 1
-- pixels between the bar + the line under it
local LABEL_OFFSET = 10
-- from here on the player doesn't have to wait for the rest
local SKIP_PERCENT = 31
-- a shade off the light accent of the palette
local BAR_COLOR = Color3.fromRGB(57, 188, 234)
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function mask(props: { AnchorPoint: Vector2, Position: UDim2 })
	local style = React.useContext(StyleContext)
	return e("Frame", {
		AnchorPoint = props.AnchorPoint,
		BackgroundColor3 = style.Palette.Field,
		BorderSizePixel = 0,
		Position = props.Position,
		Size = UDim2.fromScale(1, 1),
		ZIndex = 3,
	})
end
-- Class
-- the logo of the studio over drifting stars on a blank screen, with a bar that says how far the load is
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local spaceRef: { current: ImageLabel? } = React.useRef(nil :: ImageLabel?)
	local veilRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local barRef: { current: Frame? } = React.useRef(nil :: Frame?)
	-- what the bar said when the rest was skipped, it says so until it's gone
	local skippedPercent: number?, setSkippedPercent: (number?) -> () = React.useState(nil :: number?)
	local percent = skippedPercent or math.clamp(math.floor(props.Progress * 100), 0, 100)
	local isSkippable = percent >= SKIP_PERCENT
	local isDone = props.Progress >= 1
	local isDoneRef = React.useRef(isDone)
	isDoneRef.current = isDone

	React.useEffect(function()
		local space = spaceRef.current
		local veil = veilRef.current
		local bar = barRef.current
		if not space or not veil or not bar then
			return function() end
		end
		local drift = TweenService:Create(space, SPACE_TWEEN_INFO, {
			Position = SPACE_AWAY_POSITION,
		})
		local fadeIn = TweenService:Create(veil, FADE_IN_TWEEN_INFO, {
			BackgroundTransparency = 1,
		})
		local barIn = TweenService:Create(bar, BAR_IN_TWEEN_INFO, {
			Position = BAR_POSITION,
		})
		local isDead = false
		drift:Play()
		fadeIn:Play()
		task.delay(BAR_DELAY, function()
			-- a load that's over by now never gets to show its bar
			if not isDead and not isDoneRef.current then
				barIn:Play()
			end
		end)
		return function()
			isDead = true
			for _, tween in { drift, fadeIn, barIn } do
				tween:Cancel()
				tween:Destroy()
			end
		end
	end, {})

	React.useEffect(function()
		local veil = veilRef.current
		local bar = barRef.current
		if not isDone or not veil or not bar then
			return function() end
		end
		local barOut = TweenService:Create(bar, BAR_OUT_TWEEN_INFO, {
			Position = BAR_AWAY_POSITION,
		})
		local fadeOut = TweenService:Create(veil, FADE_OUT_TWEEN_INFO, {
			BackgroundTransparency = 0,
		})
		local isDead = false
		task.delay(LEAVE_DELAY, function()
			if isDead then
				return
			end
			barOut:Play()
			fadeOut:Play()
		end)
		return function()
			isDead = true
			for _, tween in { barOut, fadeOut } do
				tween:Cancel()
				tween:Destroy()
			end
		end
	end, { isDone })

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			-- covers the top bar inset
			Backdrop = e("Frame", {
				Active = true,
				BackgroundColor3 = style.Palette.Field,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, -1),
				Size = UDim2.fromScale(1, 2),
			}),

			Logo = e(
				"Frame",
				{
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					ClipsDescendants = true,
					Position = UDim2.fromScale(0.4994, 0.312),
					Size = UDim2.fromScale(0.7, 0.7),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					ZIndex = 2,
				} :: RobloxComponents.FrameProperties,
				{
					Space = e(
						"ImageLabel",
						{
							ref = spaceRef,
							BackgroundTransparency = 1,
							ImageContent = Content.fromUri(SPACE_URL),
							Size = UDim2.fromScale(SPACE_SIZE, SPACE_SIZE),
						} :: RobloxComponents.ImageLabelProperties
					),

					Picture = e("ImageLabel", {
						BackgroundTransparency = 1,
						ImageContent = Content.fromUri(LOGO_URL),
						Size = UDim2.fromScale(1, 1),
						ZIndex = 2,
					}),

					LeftMask = e(mask, {
						AnchorPoint = Vector2.new(1, 0.5),
						Position = UDim2.fromScale(MASK_INSET, 0.5),
					}),
					RightMask = e(mask, {
						AnchorPoint = Vector2.new(0, 0.5),
						Position = UDim2.fromScale(1 - MASK_INSET, 0.5),
					}),
					TopMask = e(mask, {
						AnchorPoint = Vector2.new(0.5, 1),
						Position = UDim2.fromScale(0.5, MASK_INSET),
					}),
					BottomMask = e(mask, {
						AnchorPoint = Vector2.new(0.5, 0),
						Position = UDim2.fromScale(0.5, 1 - MASK_INSET),
					}),
				}
			),

			-- what the logo comes out of + what all of it goes back into, the bar stays in front of it
			Veil = e(
				"Frame",
				{
					ref = veilRef,
					BackgroundColor3 = style.Palette.Field,
					BackgroundTransparency = 0,
					BorderSizePixel = 0,
					Position = UDim2.fromScale(0, -1),
					Size = UDim2.fromScale(1, 2),
					ZIndex = 3,
				} :: RobloxComponents.FrameProperties
			),

			Bar = e(
				"Frame",
				{
					ref = barRef,
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = BAR_COLOR,
					BorderSizePixel = 0,
					Position = BAR_AWAY_POSITION,
					Size = UDim2.fromScale(0.8, 0.04),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					ZIndex = 4,
				} :: RobloxComponents.FrameProperties,
				{
					-- it's set, not slid: a load comes in steps
					Fill = e("Frame", {
						AnchorPoint = Vector2.new(0, 0.5),
						BackgroundColor3 = style.Palette.Field,
						BorderSizePixel = 0,
						Position = UDim2.new(0, FILL_INSET, 0.5, 0),
						Size = UDim2.new(math.max(percent, MIN_PERCENT) / 100, -2 * FILL_INSET, 1, -2 * FILL_INSET),
					}),

					Label = e("TextLabel", {
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundTransparency = 1,
						FontFace = style.Fonts.Body,
						Position = UDim2.new(0.5, 0, 1, LABEL_OFFSET),
						Size = UDim2.fromScale(1, 0.6),
						Text = if isSkippable then `{percent}% loaded. Click to skip` else `{percent}% loaded.`,
						TextColor3 = BAR_COLOR,
						TextScaled = true,
						TextWrapped = true,
						ZIndex = 2,
					}),
				}
			),

			-- the whole screen is the button, there's nothing on it to see
			Skip = isSkippable and e(
				"ImageButton",
				{
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 5,
					[React.Event.Activated] = function()
						if skippedPercent or isDone then
							return
						end
						setSkippedPercent(percent)
						props.OnAction({
							Type = "Skip",
						})
					end,
				} :: RobloxComponents.ImageButtonProperties
			),
		}
	))
end
