--!strict
--!native
-- Services
local TweenService = game:GetService("TweenService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
-- Components
-- Hooks
-- Contexts
local AppBootPhaseContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/BootPhase")
-- Types
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type BootPhase = AppBootPhaseContext.BootPhase
export type DailyReward = SessionType.DailyReward
export type ActionInfo = {
	Type: "Dismiss",
}
export type Properties = RobloxComponents.FrameProperties & {
	Reward: DailyReward?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local REST_POSITION = UDim2.fromScale(-0.5, 0.5)
local SHOWN_POSITION = UDim2.fromScale(0.5, 0.5)
local GONE_POSITION = UDim2.fromScale(1.5, 0.5)
local TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local bootPhase: BootPhase = React.useContext(AppBootPhaseContext) :: BootPhase
	local isShown = props.Reward ~= nil and bootPhase == "Playing"
	local rewardRef: { current: DailyReward? } = React.useRef(props.Reward)
	if props.Reward then
		rewardRef.current = props.Reward
	end
	local reward = rewardRef.current

	local panelRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local hasShownRef = React.useRef(false)
	React.useEffect(function()
		local inst = panelRef.current
		if not inst or not (isShown or hasShownRef.current) then
			return function() end
		end
		if isShown then
			hasShownRef.current = true
			inst.Position = REST_POSITION
		end
		local tween = TweenService:Create(inst, TWEEN_INFO, {
			Position = isShown and SHOWN_POSITION or GONE_POSITION,
		})
		tween:Play()
		return function()
			tween:Cancel()
			tween:Destroy()
		end
	end, { isShown })

	return e(RobloxComponents.Frame(
		{
			Active = false,
			BackgroundTransparency = 1,
		},
		props,
		{
			Panel = e(
				"Frame",
				{
					ref = panelRef,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.3,
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					Position = REST_POSITION,
					Size = UDim2.fromScale(0.3, 0.1),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
				} :: RobloxComponents.FrameProperties,
				{
					Message = e("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
						Size = UDim2.fromScale(1, 0.6),
						Text = if reward
							then `Enjoy your {reward.Amount} {ProductDefinition.getCurrencyName(reward.Currency)}! Rejoin the game tomorrow for more!`
							else "",
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
					}),
					Dismiss = e(
						"TextButton",
						{
							AnchorPoint = Vector2.new(0.5, 0),
							BackgroundColor3 = Color3.fromRGB(0, 170, 255),
							BorderColor3 = Color3.fromRGB(27, 42, 53),
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
							Position = UDim2.fromScale(0.5, 0.65),
							Selectable = isShown, -- nothing for a gamepad to pick off screen
							Size = UDim2.fromScale(0.5, 0.3),
							Text = "Sounds good!",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							[React.Event.Activated] = isShown and function()
								props.OnAction({
									Type = "Dismiss",
								})
							end or nil,
						} :: RobloxComponents.TextButtonProperties
					),
				}
			),
		}
	))
end
