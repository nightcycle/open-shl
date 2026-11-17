--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local PunDefinition = require("@game/ReplicatedStorage/Shared/Definition/Pun")
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
	controls = {},
}, function(props)
	local playCount, setPlayCount = React.useState(1)
	local pun = React.useMemo(function(): string
		return PunDefinition.roll(Random.new(playCount))
	end, { playCount })

	local intros: { [string]: React.ReactNode } = {}
	intros[`Intro-{playCount}`] = e(
		ParentComponent,
		{
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			Pun = pun,
			OnAction = function(action: ParentComponent.ActionInfo)
				if action.Type == "FadedOut" then
					setPlayCount(playCount + 1)
				end
			end,
			SizeConstraint = Enum.SizeConstraint.RelativeXY,
		} :: ParentComponent.Properties
	)
	return e(React.Fragment, {}, intros)
end)
