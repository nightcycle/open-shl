--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local CONSTANTS = require("@self/CONSTANTS")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local Scene = require("@self/Scene")
-- Hooks
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Contexts
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type Phase = CONSTANTS.Phase
export type ItemDefinition = AppearanceType.ItemDefinition
export type ActionInfo = {
	Type: "Exit",
}
export type Properties = RobloxComponents.FrameProperties & {
	ItemDefinition: ItemDefinition,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local LABEL_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local TITLE_HIDDEN_POSITION = UDim2.fromScale(0.5, -0.175)
local TITLE_SHOWN_POSITION = UDim2.fromScale(0.5, 0.175)
local TITLE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local phase: Phase, setPhase: (Phase) -> () = React.useState("Closed" :: Phase)
	local onActionRef = React.useRef(props.OnAction)
	onActionRef.current = props.OnAction
	local itemIndexRes = React.useMemo(function()
		return ItemAppearanceDefinition.getIndex(props.ItemDefinition.Id)
	end, { props.ItemDefinition.Id })

	-- the buttons only ever skip ahead, a phase that nobody ends is over once its time is up
	React.useEffect(function()
		local isDead = false
		task.delay(CONSTANTS.PHASE_DURATIONS[phase], function()
			if isDead then
				return
			end
			local nextPhase: Phase? = CONSTANTS.NEXT_PHASES[phase]
			if nextPhase then
				setPhase(nextPhase)
			else
				onActionRef.current({
					Type = "Exit",
				})
			end
		end)
		return function()
			isDead = true
		end
	end, { phase })

	local titleRef: { current: TextLabel? } = React.useRef(nil :: TextLabel?)
	local isTitleShown = phase == "Revealed"
	useTween(titleRef, TITLE_TWEEN_INFO, {
		Position = isTitleShown and TITLE_SHOWN_POSITION or TITLE_HIDDEN_POSITION,
	}, { isTitleShown })

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			Backdrop = e("Frame", {
				Active = true,
				BackgroundColor3 = Color3.new(),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, -1),
				Size = UDim2.fromScale(1, 2),
				ZIndex = -1,
			}),
			Scene = e(
				Scene,
				{
					ItemDefinition = props.ItemDefinition,
					IsOpen = phase ~= "Closed",
				} :: Scene.Properties
			),
			Title = e(
				"TextLabel",
				{
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundTransparency = 1,
					FontFace = LABEL_FONT,
					Position = TITLE_HIDDEN_POSITION,
					Size = UDim2.fromScale(0.75, 0.075),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = props.ItemDefinition.Name or itemIndexRes.IsOk and itemIndexRes.Value.Key or "...",
					TextColor3 = Color3.new(),
					TextScaled = true,
					-- on a wide + short screen the tier would peek in from above while the name waits up there
					Visible = phase == "Revealed" or phase == "Leaving",
					ref = titleRef,
				} :: RobloxComponents.TextLabelProperties,
				{
					Tier = props.ItemDefinition.Rarity and e("TextLabel", {
						AnchorPoint = Vector2.new(0.5, 1),
						BackgroundTransparency = 1,
						FontFace = LABEL_FONT,
						Position = UDim2.fromScale(0.5, 1.35),
						Size = UDim2.fromScale(0.25, 0.05),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						Text = props.ItemDefinition.Rarity == PseudoEnum.Rarity.VeryCommon and "Very Common"
							or props.ItemDefinition.Rarity,
						TextColor3 = Color3.fromRGB(255, 170, 0),
						TextScaled = true,
					}),
				}
			),
			Button = (phase == "Closed" or phase == "Revealed") and e(
				"TextButton",
				{
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundColor3 = Color3.new(),
					BorderColor3 = Color3.fromRGB(27, 42, 53),
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					-- a mouse the camera holds on to couldn't reach it
					Modal = true,
					Position = UDim2.fromScale(0.5, 0.9),
					Size = UDim2.fromScale(0.15, 0.075),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = phase == "Closed" and "Open" or "Continue",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					[React.Event.Activated] = function()
						setPhase(if phase == "Closed" then "Opening" :: Phase else "Leaving" :: Phase)
					end,
				} :: RobloxComponents.TextButtonProperties
			),
		}
	))
end
