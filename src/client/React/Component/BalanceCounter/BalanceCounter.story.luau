--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
-- Constants
local CURRENCIES = PseudoEnum.getEnumItems("Currency")
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl(),
		Currency = UILabs.Choose(CURRENCIES),
		Balance = UILabs.Slider(250, 0, 100_000, 1),
	},
}, function(props)
	return StyleStory.provide(props.controls.Style, {
		Counter = e(
			ParentComponent,
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.3, 0.03),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Currency = props.controls.Currency,
				Balance = props.controls.Balance,
			} :: ParentComponent.Properties
		),
	})
end)
