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
-- one of the lines the server has for a code that paid nothing
local REFUSAL_TEXT = "That code doesn't exist"
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
		-- stands in for the server: on, whatever is typed pays nothing + the box says why
		IsRefused = UILabs.Boolean(false),
	},
}, function(props)
	local text, setText = React.useState("")
	local notice: string?, setNotice: (string?) -> () = React.useState(nil :: string?)
	local isRefused: boolean = props.controls.IsRefused

	return StyleStory.provide(props.controls.Style, {
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			ClipsDescendants = true,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			Box = e(
				ParentComponent,
				{
					Size = UDim2.fromScale(1, 1),
					Text = text,
					Notice = notice,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "Change" then
							setText(action.Text)
						elseif action.Type == "Focus" then
							setNotice(nil)
						elseif action.Type == "Submit" then
							-- emptied either way: paid, or with the line that says why not
							setText("")
							setNotice(if isRefused then REFUSAL_TEXT else nil)
						end
					end,
				} :: ParentComponent.Properties
			),
		}),
	})
end)
