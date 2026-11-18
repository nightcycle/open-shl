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
		Style = StyleStory.newControl("shl3"),
		-- the bar slides up three seconds in, a full one takes all of it away
		Progress = UILabs.Slider(0.5, 0, 1, 0.01),
	},
}, function(props)
	return StyleStory.provide(props.controls.Style, {
		Preload = e(
			ParentComponent,
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				Progress = props.controls.Progress,
				OnAction = function(action: ParentComponent.ActionInfo)
					print(`action`, action)
				end,
				SizeConstraint = Enum.SizeConstraint.RelativeXY,
			} :: ParentComponent.Properties
		),
	})
end)
