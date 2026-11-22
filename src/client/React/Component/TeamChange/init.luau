--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
local Dialog = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Dialog")
-- Hooks
local useSlide = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSlide")
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
type ButtonInfo = Dialog.ButtonInfo
export type ActionInfo =
	{
		Type: "Confirm", -- the other side is asked for
	}
	| {
		Type: "Exit", -- the panel slid back out
	}
export type Properties = RobloxComponents.FrameProperties & {
	-- why the last ask was turned down, read in place of the question for as long as it's handed in
	Refusal: string?,
	-- the ask went through: the panel leaves the way it came
	IsLeaving: boolean?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local TITLE_TEXT = "TEAM CHANGER"
local QUESTION_TEXT = "Would you like to change team?"
local YES_ID = "Yes"
local NO_ID = "No"
local BUTTONS: { ButtonInfo } = table.freeze({
	table.freeze({ Id = YES_ID, Text = "Yes" }),
	table.freeze({ Id = NO_ID, Text = "No" }),
})
-- the picture of the panel is a square of this much of the width of the screen, larger than the panel that's seen
local PANEL_SIZE = UDim2.fromScale(0.35, 0.35)
local OPEN_POSITION = UDim2.fromScale(0.5, 0.5)
-- where it's kept, off the right edge of the screen
local AWAY_POSITION = UDim2.fromScale(1.5, 0.5)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the question of the legacy place whether to go over to the other side: it comes in from the right + leaves that way
-- on a no, or once the other side was had. turned down, it stays + says why
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local panelRef, initialPosition, close = useSlide(OPEN_POSITION, AWAY_POSITION, style.Motion.Slide, function()
		props.OnAction({
			Type = "Exit",
		})
	end)
	-- a press on a panel that's on its way out is one too many
	local isLeavingRef = React.useRef(false)
	local function leave()
		isLeavingRef.current = true
		close()
	end
	local isLeaving = props.IsLeaving == true
	React.useEffect(function()
		if isLeaving then
			leave()
		end
		return function() end
	end, { isLeaving })

	return e(RobloxComponents.Frame(
		{
			Active = false,
			BackgroundTransparency = 1,
		},
		props,
		{
			Panel = e("Frame", {
				ref = panelRef,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = initialPosition,
				Size = PANEL_SIZE,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}, {
				Dialog = e(
					Dialog,
					{
						Size = UDim2.fromScale(1, 1),
						Title = TITLE_TEXT,
						Text = props.Refusal or QUESTION_TEXT,
						Buttons = BUTTONS,
						OnAction = function(action: Dialog.ActionInfo)
							if action.Type ~= "Press" or isLeavingRef.current then
								return
							end
							if action.Id == YES_ID then
								props.OnAction({
									Type = "Confirm",
								})
							elseif action.Id == NO_ID then
								leave()
							end
						end,
					} :: Dialog.Properties
				),
			}),
		}
	))
end
