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
-- the grey box stands in for the screen: the bar sits in its bottom right corner, in pixels whatever size it has
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Caption = UILabs.String("Machine Gun"),
		Count = UILabs.Slider(45, 0, 45, 1),
		Max = UILabs.Slider(45, 1, 100, 1),
		IsReloading = UILabs.Boolean(false),
	},
}, function(props)
	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(127, 127, 127),
		ClipsDescendants = true,
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.9),
	}, {
		AmmoBar = e(
			ParentComponent,
			{
				Size = UDim2.fromScale(1, 1),
				Caption = props.controls.Caption,
				Count = props.controls.Count,
				Max = props.controls.Max,
				Text = if props.controls.IsReloading then "Reloading" else nil,
			} :: ParentComponent.Properties
		),
	})
end)
