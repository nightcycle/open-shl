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
-- Components
local ArtifactMenu = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ArtifactMenu")
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
	local currentMenuId: PseudoEnum.MenuId?, setCurrentMenuId: (PseudoEnum.MenuId?) -> () =
		React.useState(nil :: PseudoEnum.MenuId?)
	return e(CharacterHealthContext.Provider, {
		value = props.controls.Health,
	}, {
		EnergyProvider = e(CharacterEnergyContext.Provider, {
			value = props.controls.Energy,
		}, {
			Screen = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.75, 0.75),
			}, {
				ArtifactMenu = currentMenuId == PseudoEnum.MenuId.Artifact and e(
					ArtifactMenu,
					{
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
						ItemDefinitions = {},
						OnAction = function(action: ArtifactMenu.ActionInfo)
							if action.Type == "Exit" then
								setCurrentMenuId(nil)
							end
						end,
					} :: ArtifactMenu.Properties
				),
				HUD = currentMenuId == nil and e(ParentComponent, {
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
					OnClick = function(menuId: PseudoEnum.MenuId)
						setCurrentMenuId(menuId)
					end,
					SizeConstraint = Enum.SizeConstraint.RelativeXY,
				}),
			}),
		}),
	})
end)
