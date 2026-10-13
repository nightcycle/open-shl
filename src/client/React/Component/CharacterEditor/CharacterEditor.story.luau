--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local RandomCharacter = require("@game/ReplicatedStorage/Shared/Random/Character")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {},
}, function(props)
	local character = React.useMemo(function(): CharacterType.Character
		return RandomCharacter.Character()
	end, {})
	return e(CharacterContext.Provider, {
		value = character,
	}, {
		Menu = e(ParentComponent, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			OnAction = function(action: ParentComponent.ActionInfo)
				print(`action`, action)
			end,
			SizeConstraint = Enum.SizeConstraint.RelativeXY,
		}),
	})
end)
