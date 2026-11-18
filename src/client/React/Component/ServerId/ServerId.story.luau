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
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Id = UILabs.String("a1b2c3"),
		Style = StyleStory.newControl(),
	},
}, function(props)
	return StyleStory.provide(props.controls.Style, {
		ServerId = e(
			ParentComponent,
			{
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromOffset(150, 30),
				Id = props.controls.Id,
			} :: ParentComponent.Properties
		),
	})
end)
