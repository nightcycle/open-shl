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
-- Contexts
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
	OnAction: (ActionInfo) -> (),
}
-- Constants
-- a button is a square of this much of the height of the screen
local BUTTON_SIZE = 0.075
-- how many pixels it stays off the edge it's on
local EDGE_OFFSET = 10
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- a hud without bars or columns: every menu is a picture on the left or the right edge of the screen
return function(props: Properties): React.ReactNode
	local fades = props.Fades

	local buttons: { [string]: React.ReactNode } = {}
	local function insert(buttonInfo: ButtonInfo, isRight: boolean)
		local position = buttonInfo.Position
		-- one that was never given a height isn't one of this hud
		if not position then
			return
		end
		local fade: number? = if fades then fades[buttonInfo.MenuId] else nil
		buttons[`{buttonInfo.MenuId}`] = e(
			"ImageButton",
			{
				AnchorPoint = Vector2.new(isRight and 1 or 0, 0.5),
				BackgroundTransparency = 1,
				ImageContent = Content.fromUri(buttonInfo.Image),
				ImageTransparency = fade or 0,
				Position = UDim2.new(isRight and 1 or 0, isRight and -EDGE_OFFSET or EDGE_OFFSET, position, 0),
				Size = UDim2.fromScale(BUTTON_SIZE, BUTTON_SIZE),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				[React.Event.Activated] = function()
					if fade then
						return
					end
					props.OnAction({
						Type = "Press",
						MenuId = buttonInfo.MenuId,
					})
				end,
			} :: RobloxComponents.ImageButtonProperties
		)
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
