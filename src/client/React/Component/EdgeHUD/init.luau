--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
-- Hooks
local useTween = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTween")
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local HUDTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/HUD/Types")
type ButtonInfo = HUDTypes.ButtonInfo
export type Buttons = HUDTypes.Buttons
export type ActionInfo = {
	Type: "Press",
	MenuId: PseudoEnum.MenuId,
}
export type Properties = RobloxComponents.FrameProperties & {
	-- a build button has no place on it, only the two columns are drawn
	Buttons: Buttons,
	-- a button that's faded can't be pressed, the number is how much of it is seen through
	Fades: { [PseudoEnum.MenuId]: number }?,
	-- a button that's away is slid off its edge of the screen until it isn't any more
	Away: { [PseudoEnum.MenuId]: true }?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
-- a button is a square of this much of the height of the screen
local BUTTON_SIZE = 0.075
-- how many pixels it stays off the edge it's on
local EDGE_OFFSET = 10
-- how far past its edge one that's away is kept, in scale of the width of the screen
local AWAY_OFFSET = 0.25
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function button(
	props: {
		ButtonInfo: ButtonInfo,
		-- how far down the screen it sits
		Height: number,
		IsRight: boolean,
		Fade: number?,
		IsAway: boolean,
		OnPress: () -> (),
	}
)
	local style = React.useContext(StyleContext)
	local isRight = props.IsRight
	local position = if props.IsAway
		then UDim2.fromScale(isRight and 1 + AWAY_OFFSET or -AWAY_OFFSET, props.Height)
		else UDim2.new(isRight and 1 or 0, isRight and -EDGE_OFFSET or EDGE_OFFSET, props.Height, 0)
	local buttonRef: { current: ImageButton? } = React.useRef(nil :: ImageButton?)
	-- it's only told where it starts out: one that's away as the hud comes up was never seen leaving
	local initialPositionRef = React.useRef(position)
	useTween(buttonRef, style.Motion.Slide, {
		Position = position,
	}, { props.IsAway :: any, props.Height, isRight })

	return e(
		"ImageButton",
		{
			ref = buttonRef,
			AnchorPoint = Vector2.new(isRight and 1 or 0, 0.5),
			BackgroundTransparency = 1,
			ImageContent = Content.fromUri(props.ButtonInfo.Image),
			ImageTransparency = props.Fade or 0,
			Position = initialPositionRef.current,
			Size = UDim2.fromScale(BUTTON_SIZE, BUTTON_SIZE),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			[React.Event.Activated] = function()
				if props.Fade or props.IsAway then
					return
				end
				props.OnPress()
			end,
		} :: RobloxComponents.ImageButtonProperties
	)
end
-- Class
-- a hud without bars or columns: every menu is a picture on the left or the right edge of the screen
return function(props: Properties): React.ReactNode
	local fades = props.Fades
	local away = props.Away

	local buttons: { [string]: React.ReactNode } = {}
	local function insert(buttonInfo: ButtonInfo, isRight: boolean)
		local height = buttonInfo.Position
		-- one that was never given a height isn't one of this hud
		if not height then
			return
		end
		buttons[`{buttonInfo.MenuId}`] = e(button, {
			ButtonInfo = buttonInfo,
			Height = height,
			IsRight = isRight,
			Fade = if fades then fades[buttonInfo.MenuId] else nil,
			IsAway = away ~= nil and away[buttonInfo.MenuId] == true,
			OnPress = function()
				props.OnAction({
					Type = "Press",
					MenuId = buttonInfo.MenuId,
				})
			end,
		})
	end
	for _, buttonInfo in props.Buttons.LEFT do
		insert(buttonInfo, false)
	end
	for _, buttonInfo in props.Buttons.RIGHT do
		insert(buttonInfo, true)
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
			Active = false,
		},
		props,
		{
			Buttons = e(React.Fragment, {}, buttons),
		}
	))
end
