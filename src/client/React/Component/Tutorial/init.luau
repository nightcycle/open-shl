--!strict
--!native
-- Services
local TweenService = game:GetService("TweenService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local TutorialDefinition = require("@game/ReplicatedStorage/Shared/Definition/Tutorial")
-- Components
local Bubble = require("@self/Bubble")
-- Hooks
local useIfHomeShown = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/Tutorial/useIfHomeShown")
local useStep = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/Tutorial/useStep")
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Contexts
local AppBootPhaseContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/BootPhase")
local AppIsCameraModeContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsCameraMode")
local TutorialIsEnabledContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Tutorial/IsEnabled")
-- Types
type BootPhase = AppBootPhaseContext.BootPhase
type Pose = TutorialDefinition.Pose
export type ActionInfo =
	{
		Type: "Next",
	}
	| {
		Type: "SetEnabled",
		IsEnabled: boolean,
	}
export type Properties = RobloxComponents.FrameProperties & {
	OnAction: (ActionInfo) -> (),
}
-- Constants
local RESIZE_TWEEN_INFO = TweenInfo.new(
	TutorialDefinition.RESIZE_DURATION,
	TutorialDefinition.EASING_STYLE,
	TutorialDefinition.EASING_DIRECTION
)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local bootPhase: BootPhase = React.useContext(AppBootPhaseContext) :: BootPhase
	local isCameraMode = React.useContext(AppIsCameraModeContext)
	local isEnabled = React.useContext(TutorialIsEnabledContext)
	local step = useStep()
	local isHomeShown = useIfHomeShown()

	-- he only talks while what the step is about is on screen
	local talkStep = if step and step.Type == "Talk" and isHomeShown then step else nil
	local position = if talkStep then talkStep.CaptainPosition else TutorialDefinition.DOCK_POSITION
	local size = if talkStep then talkStep.CaptainSize else TutorialDefinition.DOCK_SIZE
	local moveDuration = if talkStep then talkStep.MoveDuration else TutorialDefinition.DOCK_DURATION

	-- nil while the tween is still running
	local arrivedPosition: Vector2?, setArrivedPosition: (Vector2?) -> () =
		React.useState(TutorialDefinition.DOCK_POSITION :: Vector2?)
	local isFlying = arrivedPosition ~= position

	local anchorRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local captainRef: { current: ImageButton? } = React.useRef(nil :: ImageButton?)
	React.useEffect(function()
		local inst = anchorRef.current
		if not inst then
			return function() end
		end
		local goal = UDim2.fromScale(position.X, position.Y)
		if inst.Position == goal then
			setArrivedPosition(position)
			return function() end
		end
		setArrivedPosition(nil)
		local tween = TweenService:Create(
			inst,
			TweenInfo.new(moveDuration, TutorialDefinition.EASING_STYLE, TutorialDefinition.EASING_DIRECTION),
			{
				Position = goal,
			}
		)
		local connection = tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
			if playbackState == Enum.PlaybackState.Completed then
				setArrivedPosition(position)
			end
		end)
		tween:Play()
		return function()
			connection:Disconnect()
			tween:Cancel()
			tween:Destroy()
		end
	end, { position.X, position.Y })
	useTween(captainRef, RESIZE_TWEEN_INFO, {
		Size = UDim2.fromScale(size, size),
	}, { size })

	local pose: Pose = if isFlying then "Fly" elseif talkStep then talkStep.Pose else "Idle"
	local bubble: React.ReactNode = nil
	if talkStep and not isFlying then
		bubble = e(
			Bubble,
			{
				BubbleSide = talkStep.BubbleSide,
				Text = talkStep.Text,
				ZIndex = 1,
				OnNext = if talkStep.Advance.Type == "Next"
					then function()
						props.OnAction({
							Type = "Next",
						})
					end
					else nil,
			} :: Bubble.Properties
		)
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Active = false,
			-- he sits out the rest of the boot, on the mode screen he has a word to say
			Visible = (bootPhase == "Playing" or bootPhase == "ModeSelect") and not isCameraMode,
		},
		props,
		{
			Anchor = e(
				"Frame",
				{
					ref = anchorRef,
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(TutorialDefinition.DOCK_POSITION.X, TutorialDefinition.DOCK_POSITION.Y),
					Size = UDim2.fromScale(TutorialDefinition.FRAME_SIZE, TutorialDefinition.FRAME_SIZE),
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					BackgroundTransparency = 1,
					Active = false,
				} :: RobloxComponents.FrameProperties,
				{
					Bubble = bubble,
					Captain = e(
						"ImageButton",
						{
							ref = captainRef,
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromScale(TutorialDefinition.DOCK_SIZE, TutorialDefinition.DOCK_SIZE),
							SizeConstraint = Enum.SizeConstraint.RelativeYY,
							BackgroundTransparency = 1,
							ImageContent = Content.fromUri(TutorialDefinition.POSE_IMAGES[pose]),
							ImageTransparency = isEnabled and 0 or TutorialDefinition.DISABLED_TRANSPARENCY,
							ZIndex = 2,
							[React.Event.Activated] = function()
								props.OnAction({
									Type = "SetEnabled",
									IsEnabled = not isEnabled,
								})
							end,
						} :: RobloxComponents.ImageButtonProperties
					),
				}
			),
		}
	))
end
