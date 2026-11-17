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
		IsDead = UILabs.Boolean(false),
	},
}, function(props)
	-- the flash shows in the viewport of the place, not in the story
	local flinchCount, setFlinchCount = React.useState(0)
	return e(CharacterHealthContext.Provider, {
		value = props.controls.Health,
	}, {
		Feedback = e(
			ParentComponent,
			{
				IsDead = props.controls.IsDead,
				OnAction = function(action: ParentComponent.ActionInfo)
					if action.Type == "Hurt" and action.Health > 0 then
						setFlinchCount(flinchCount + 1)
					end
				end,
			} :: ParentComponent.Properties
		),
		Count = e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.5,
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.3, 0.1),
			Text = `lower the health to get hit, flinched {flinchCount} times`,
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
		}),
	})
end)
