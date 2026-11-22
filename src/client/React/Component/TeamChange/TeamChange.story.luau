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
-- what the server of the old place said to whoever asked while the sides were too far apart
local REFUSAL_TEXT = "Teams are too unbalanced to switch right now"
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
		-- stands in for the server: on, a yes is turned down + the panel stays
		IsRefused = UILabs.Boolean(false),
	},
}, function(props)
	local isOpen, setIsOpen = React.useState(true)
	local refusal: string?, setRefusal: (string?) -> () = React.useState(nil :: string?)
	local isLeaving, setIsLeaving = React.useState(false)
	local isRefused: boolean = props.controls.IsRefused

	return StyleStory.provide(props.controls.Style, {
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			ClipsDescendants = true,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			Menu = isOpen and e(
				ParentComponent,
				{
					Size = UDim2.fromScale(1, 1),
					Refusal = refusal,
					IsLeaving = isLeaving,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "Confirm" then
							if isRefused then
								setRefusal(REFUSAL_TEXT)
							else
								setIsLeaving(true)
							end
						elseif action.Type == "Exit" then
							setIsOpen(false)
						end
					end,
				} :: ParentComponent.Properties
			),
			-- stands in for the hud button, which is where the panel is opened from. it asks the question anew
			Open = not isOpen and e("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				BackgroundColor3 = Color3.fromRGB(20, 166, 230),
				BorderSizePixel = 0,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.new(1, -10, 0.6, 0),
				Size = UDim2.fromScale(0.075, 0.075),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				Text = "Team",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				[React.Event.Activated] = function()
					setRefusal(nil)
					setIsLeaving(false)
					setIsOpen(true)
				end,
			}),
		}),
	})
end)
