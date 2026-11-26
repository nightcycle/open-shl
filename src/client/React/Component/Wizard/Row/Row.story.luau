--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/CONSTANTS")
-- what a row reads: its name, or what it says while what it has on is held back from the player
local TEXTS: { string } = table.freeze({ "HAIR", CONSTANTS.GATE_PASS_TEXT, CONSTANTS.GATE_GROUP_TEXT })
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl1"),
		Text = UILabs.Choose(TEXTS),
		IsLive = UILabs.Boolean(true),
	},
}, function(props)
	local text: string = props.controls.Text
	local isGated = text ~= TEXTS[1]
	-- what was pressed last, a row says nothing of it by itself
	local pressed, setPressed = React.useState("nothing was pressed")

	return StyleStory.provide(props.controls.Style, {
		Row = e(
			ParentComponent,
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.4),
				Size = UDim2.fromScale(0.285, 0.075),
				Text = text,
				NameColor3 = if isGated then CONSTANTS.GATE_COLOR else nil,
				LeftPosition = CONSTANTS.ROW_LEFT_POSITION,
				RightPosition = CONSTANTS.ROW_RIGHT_POSITION,
				ArrowSize = CONSTANTS.ROW_ARROW_SIZE,
				NamePosition = CONSTANTS.ROW_NAME_POSITION,
				NameSize = CONSTANTS.ROW_NAME_SIZE,
				OnStep = if props.controls.IsLive
					then function(direction: number)
						setPressed(if direction > 0 then "the right arrow" else "the left arrow")
					end
					else nil,
				-- only what's behind a pass is pressed: the press asks for the pass
				OnName = if props.controls.IsLive and text == CONSTANTS.GATE_PASS_TEXT
					then function()
						setPressed("the name")
					end
					else nil,
			} :: ParentComponent.Properties
		),
		Pressed = e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.285, 0.04),
			Text = pressed,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
		}),
	})
end)
