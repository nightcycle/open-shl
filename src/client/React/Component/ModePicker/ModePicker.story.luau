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
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
-- Types
-- Constants
-- how long a choice is on its way before it falls through
local LEAVE_DURATION = 2
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
		-- what a choice that fell through is answered with, every choice made in here does
		Notice = UILabs.String("roleplay isn't available yet"),
	},
}, function(props)
	local isLeaving: boolean?, setIsLeaving: (boolean?) -> () = useTimedState(LEAVE_DURATION)
	local hasLeft, setHasLeft = React.useState(false)
	local notice: string = props.controls.Notice
	local isBack = hasLeft and not isLeaving

	return StyleStory.provide(props.controls.Style, {
		ModePicker = e(
			ParentComponent,
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				IsLeaving = isLeaving == true,
				Notice = if isBack and notice ~= "" then notice else nil,
				OnAction = function(action: ParentComponent.ActionInfo)
					print(`action`, action)
					if action.Type == "ModePressed" then
						setHasLeft(true)
						setIsLeaving(true)
					end
				end,
				SizeConstraint = Enum.SizeConstraint.RelativeXY,
			} :: ParentComponent.Properties
		),
	})
end)
