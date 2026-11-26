--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Text = "BRAINFREEZE!",
		IsShown = UILabs.Boolean(true),
		TextColor3 = Color3.new(1, 0, 0),
	},
}, function(props)
	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(127, 127, 127),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, {
		Notice = e(
			ParentComponent,
			{
				Size = UDim2.fromScale(1, 1),
				Text = if props.controls.IsShown then props.controls.Text else nil,
				TextColor3 = props.controls.TextColor3,
			} :: ParentComponent.Properties
		),
	})
end)
