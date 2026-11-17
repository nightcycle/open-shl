--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local QuestDefinition = require("@game/ReplicatedStorage/Shared/Definition/Quest")
-- Components
-- Hooks
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Contexts
-- Types
local QuestType = require("@game/ReplicatedStorage/Shared/Type/Quest")
export type QuestState = QuestType.QuestState
export type ActionInfo = {
	Type: "Cancel",
}
export type Properties = RobloxComponents.FrameProperties & {
	Quest: QuestState?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local SHOWN_POSITION = UDim2.fromScale(0.66, 0.01)
local HIDDEN_POSITION = UDim2.fromScale(0.66, -1.01)
local BANNER_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local DISMISS_DURATION = 5
local LABEL_FONT = Font.new("rbxasset://fonts/families/ComicNeueAngular.json")
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local currentQuest = props.Quest
	local isActive = currentQuest ~= nil and currentQuest.Status == "Active"
	-- hide right away, come back if the server never fails the quest
	local isDismissed, setIsDismissed = React.useState(false)
	React.useEffect(function()
		if not isActive then
			setIsDismissed(false)
		end
		return function() end
	end, { isActive })
	React.useEffect(function()
		if not isDismissed then
			return function() end
		end
		local isDead = false
		task.delay(DISMISS_DURATION, function()
			if not isDead then
				setIsDismissed(false)
			end
		end)
		return function()
			isDead = true
		end
	end, { isDismissed })
	local isShown = isActive and not isDismissed
	local questRef = React.useRef(currentQuest)
	if currentQuest then
		questRef.current = currentQuest
	end
	local quest: QuestState? = questRef.current

	local bannerRef: { current: Frame? } = React.useRef(nil :: Frame?)
	local initialPositionRef = React.useRef(isShown and SHOWN_POSITION or HIDDEN_POSITION)
	useTween(bannerRef, BANNER_TWEEN_INFO, {
		Position = isShown and SHOWN_POSITION or HIDDEN_POSITION,
	}, { isShown })

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Active = false,
		},
		props,
		{
			Banner = e(
				"Frame",
				{
					ref = bannerRef,
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.5,
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					Position = initialPositionRef.current,
					Size = UDim2.new(0.33, 0, 0, 45),
				} :: RobloxComponents.FrameProperties,
				{
					Instruction = e("TextLabel", {
						BackgroundTransparency = 1,
						FontFace = LABEL_FONT,
						Size = UDim2.fromScale(0.7, 1),
						Text = quest and `"{quest.Instruction}"` or "", -- quoted, it's what the quest giver said
						TextColor3 = Color3.new(1, 1, 1),
						TextScaled = true,
						TextStrokeTransparency = 0.5,
					}),
					Cancel = e(
						"TextButton",
						{
							AnchorPoint = Vector2.new(0, 1),
							BackgroundColor3 = Color3.fromRGB(255, 0, 0),
							BorderColor3 = Color3.fromRGB(27, 42, 53),
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
							Position = UDim2.fromScale(0.75, 0.9),
							Size = UDim2.fromScale(0.2, 0.075),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							Text = "Cancel",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							Active = isShown,
							Interactable = isShown,
							Selectable = isShown,
							[React.Event.Activated] = function()
								setIsDismissed(true)
								props.OnAction({
									Type = "Cancel",
								})
							end,
						} :: RobloxComponents.TextButtonProperties
					),
					Timer = e("Frame", {
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundColor3 = Color3.new(),
						BackgroundTransparency = 0.5,
						BorderColor3 = Color3.fromRGB(27, 42, 53),
						Position = UDim2.fromScale(0.5, 1.1),
						Size = UDim2.new(0.2, 0, 0, 30),
					}, {
						Countdown = e("TextLabel", {
							BackgroundTransparency = 1,
							FontFace = LABEL_FONT,
							Size = UDim2.fromScale(1, 1),
							Text = quest and QuestDefinition.formatCountdown(quest.SecondsRemaining) or "",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							TextStrokeTransparency = 0.5,
						}),
					}),
				}
			),
		}
	))
end
