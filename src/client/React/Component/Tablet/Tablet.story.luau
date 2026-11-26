--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
-- Constants
local TABLET = Image["shl-3"].prop.tablet
-- all four the old gear went through, the game shows the two in the middle
local SLIDE_IMAGES = table.freeze({
	TABLET["slide-1.png"],
	TABLET["slide-2.png"],
	TABLET["slide-3.png"],
	TABLET["slide-4.png"],
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		-- off: its screen has nothing to show
		HasSlides = UILabs.Boolean(true),
		-- off: only the two of the game
		HasAllFour = UILabs.Boolean(false),
	},
}, function(props)
	-- stands in for the container: which slide is up
	local index, setIndex = React.useState(1)
	local first = if props.controls.HasAllFour then 1 else 2
	local count = if props.controls.HasAllFour then 4 else 2
	local slideImage = if props.controls.HasSlides then SLIDE_IMAGES[first + (index - 1) % count] else nil

	return e("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Color3.fromRGB(127, 127, 127),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
	}, {
		Tablet = e(
			ParentComponent,
			{
				Size = UDim2.fromScale(1, 1),
				FrameImage = TABLET["frame.png"],
				SlideImage = slideImage,
				OnAction = function(action: ParentComponent.ActionInfo)
					if action.Type == "NextSlide" then
						setIndex(index + 1)
					end
				end,
			} :: ParentComponent.Properties
		),
	})
end)
