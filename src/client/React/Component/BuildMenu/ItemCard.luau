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
local BuildTypes = require("./Types")
type CardState = BuildTypes.CardState
type Refusal = BuildTypes.Refusal
export type Properties = RobloxComponents.FrameProperties & {
	Title: string,
	ButtonText: string,
	State: CardState,
	-- there for as long as the line of the purchase this card was refused is up, a new one flashes the card again
	Refusal: Refusal?,
	OnClick: () -> (),
	children: { [string]: React.ReactNode }?,
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/BuildMenu/CONSTANTS")
local FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local isFlashing, setIsFlashing = React.useState(false)
	React.useEffect(function()
		if not props.Refusal then
			setIsFlashing(false)
			return function() end
		end
		setIsFlashing(true)
		local isDead = false
		task.delay(CONSTANTS.REFUSAL_FLASH_DURATION, function()
			if not isDead then
				setIsFlashing(false)
			end
		end)
		return function()
			isDead = true
		end
	end, { props.Refusal })

	local stateInfo = CONSTANTS.CARD_STATES[props.State]
	-- a purchase that's on its way can't be asked for again
	local isDisabled = props.State == "Purchasing"
	return e(RobloxComponents.Frame(
		{
			Active = true,
			BackgroundColor3 = isFlashing and CONSTANTS.REFUSAL_COLOR3 or stateInfo.CardColor3,
			BorderSizePixel = 0,
		},
		props,
		{
			Picture = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.05),
				Size = UDim2.fromScale(0.6, 0.6),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}, props.children),
			Title = e("TextLabel", {
				AnchorPoint = Vector2.new(0, 1),
				BackgroundTransparency = 1,
				FontFace = FONT,
				Position = UDim2.fromScale(0, 0.825),
				Size = UDim2.fromScale(1, 0.15),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = props.Title,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeTransparency = 0.5,
				-- on a card that's wider than it's tall the title runs over the picture
				ZIndex = 2,
			}),
			Action = e(
				"TextButton",
				{
					Active = not isDisabled,
					AnchorPoint = Vector2.new(0.5, 1),
					AutoButtonColor = not isDisabled,
					BackgroundColor3 = stateInfo.ButtonColor3,
					BorderSizePixel = 0,
					FontFace = FONT,
					Position = UDim2.fromScale(0.5, 0.975),
					Selectable = not isDisabled,
					Size = UDim2.fromScale(0.8, 0.125),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = props.ButtonText,
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
					TextStrokeTransparency = stateInfo.TextStrokeTransparency,
					[React.Event.Activated] = not isDisabled and function()
						props.OnClick()
					end or nil,
				} :: RobloxComponents.TextButtonProperties
			),
		}
	))
end
