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
local CharacterEnergyContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Energy")
local CharacterHealthContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Health")
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
		Health = UILabs.Slider(100, 0, 100, 1),
		Energy = UILabs.Slider(100, 0, 100, 1),
	},
}, function(props)
	return e(CharacterHealthContext.Provider, {
		value = props.controls.Health,
	}, {
		EnergyProvider = e(CharacterEnergyContext.Provider, {
			value = props.controls.Energy,
		}, {
			HUD = e(ParentComponent, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.5, 0.5),
				OnClick = function(menuId)
					print(`menuId: {menuId}`)
				end,
				SizeConstraint = Enum.SizeConstraint.RelativeXY,
			}),
		}),
	})
end)
