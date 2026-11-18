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
		IsLeaving = UILabs.Boolean(false),
		Notice = UILabs.String(""),
		IdNotice = UILabs.String(""),
	},
}, function(props)
	local notice: string = props.controls.Notice
	local idNotice: string = props.controls.IdNotice
	return e(
		ParentComponent,
		{
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
			IsLeaving = props.controls.IsLeaving,
			Notice = if notice ~= "" then notice else nil,
			IdNotice = if idNotice ~= "" then idNotice else nil,
			OnAction = function(action: ParentComponent.ActionInfo)
				print(`action`, action)
			end,
			SizeConstraint = Enum.SizeConstraint.RelativeXY,
		} :: ParentComponent.Properties
	)
end)
