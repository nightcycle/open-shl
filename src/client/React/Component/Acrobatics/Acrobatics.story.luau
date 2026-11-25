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
-- nobody is thrown anywhere in here: what a button would do is read out in the corner. the box stays where it's let
-- go of until the story is started over
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl1"),
	},
}, function(props)
	local boxPosition: UDim2?, setBoxPosition: (UDim2?) -> () = React.useState(nil :: UDim2?)
	local pressed: string?, setPressed: (string?) -> () = React.useState(nil :: string?)

	return StyleStory.provide(props.controls.Style, {
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			ClipsDescendants = true,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0.9),
		}, {
			-- stands in for the move a button throws the avatar into
			Pressed = e("TextLabel", {
				AnchorPoint = Vector2.new(0, 1),
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.fromScale(0.4, 0.08),
				Text = if pressed then `pressed {pressed}` else "nothing pressed",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),
			Panel = e(
				ParentComponent,
				{
					Size = UDim2.fromScale(1, 1),
					BoxPosition = boxPosition,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "Play" then
							setPressed(action.MoveId)
						elseif action.Type == "Fix" then
							setPressed("fix")
						elseif action.Type == "Drag" then
							setBoxPosition(action.Position)
						end
					end,
				} :: ParentComponent.Properties
			),
		}),
	})
end)
