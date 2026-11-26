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
		-- what the server plays by as the story starts, a press stands in for the server + flips it
		IsPVP = UILabs.Boolean(true),
	},
}, function(props)
	local controlIsPVP: boolean = props.controls.IsPVP
	local isPVP, setIsPVP = React.useState(controlIsPVP)
	React.useEffect(function()
		setIsPVP(controlIsPVP)
		return function() end
	end, { controlIsPVP })

	return StyleStory.provide(props.controls.Style, {
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			ClipsDescendants = true,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			Toggle = e(
				ParentComponent,
				{
					Size = UDim2.fromScale(1, 1),
					IsPVP = isPVP,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "Toggle" then
							setIsPVP(not isPVP)
						end
					end,
				} :: ParentComponent.Properties
			),
		}),
	})
end)
