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
type ButtonInfo = ParentComponent.ButtonInfo
-- Constants
local CONFIRM_BUTTONS: { ButtonInfo } = table.freeze({
	table.freeze({ Id = "Yes", Text = "Yes" }),
	table.freeze({ Id = "No", Text = "No" }),
})
local NOTICE_BUTTONS: { ButtonInfo } = table.freeze({
	table.freeze({ Id = "Okay", Text = "Okay" }),
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Title = UILabs.String("TEAM CHANGER"),
		Text = UILabs.String("Would you like to change team?"),
		IsConfirm = UILabs.Boolean(true),
		-- the box of the first game took the middle half of the screen, a card of it is looked at there
		IsHalfScreen = UILabs.Boolean(false),
		Style = StyleStory.newControl("shl3"),
	},
}, function(props)
	local pressedId: string?, setPressedId: (string?) -> () = React.useState(nil :: string?)

	return StyleStory.provide(props.controls.Style, {
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			Pressed = e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.5, 0.98),
				Size = UDim2.fromScale(0.5, 0.05),
				Text = if pressedId then `pressed {pressedId}` else "nothing pressed",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),
			-- where + how large the dialogs of the game it was drawn for stood: a square of 0.35 of the screen's width
			Dialog = e(
				ParentComponent,
				{
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = if props.controls.IsHalfScreen
						then UDim2.fromScale(0.5, 0.5)
						else UDim2.fromScale(0.35, 0.35),
					SizeConstraint = if props.controls.IsHalfScreen then nil else Enum.SizeConstraint.RelativeXX,
					Title = props.controls.Title,
					Text = props.controls.Text,
					Buttons = if props.controls.IsConfirm then CONFIRM_BUTTONS else NOTICE_BUTTONS,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "Press" then
							setPressedId(action.Id)
						end
					end,
				} :: ParentComponent.Properties
			),
		}),
	})
end)
