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
		-- what the flight over its own city comes to, 0 is a flight that isn't known yet
		Duration = UILabs.Slider(9.54, 0, 20, 0.01),
	},
}, function(props)
	local playCount, setPlayCount = React.useState(1)
	local duration: number = props.controls.Duration

	local flyIns: { [string]: React.ReactNode } = {}
	flyIns[`FlyIn-{playCount}`] = e(
		ParentComponent,
		{
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Duration = if duration > 0 then duration else nil,
			OnAction = function(action: ParentComponent.ActionInfo)
				if action.Type == "FadedOut" then
					setPlayCount(playCount + 1)
				end
			end,
			SizeConstraint = Enum.SizeConstraint.RelativeXY,
		} :: ParentComponent.Properties
	)
	return StyleStory.provide(props.controls.Style, {
		-- stands in for the city
		City = e("Frame", {
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			Size = UDim2.fromScale(1, 1),
		}, flyIns),
	})
end)
