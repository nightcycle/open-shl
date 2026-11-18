--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
-- Types
-- Constants
-- what somebody new to the game it was made for starts out with
local STARTING_CREDITS = 1000
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function balanceButton(props: RobloxComponents.TextButtonProperties)
	return e(RobloxComponents.TextButton({
		BackgroundColor3 = Color3.fromRGB(107, 107, 107),
		BorderSizePixel = 0,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
		Size = UDim2.fromScale(0.3, 1),
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
	}, props))
end
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		IsLoaded = UILabs.Boolean(true),
		Style = StyleStory.newControl("shl3"),
	},
}, function(props)
	local credits, setCredits = React.useState(STARTING_CREDITS)

	return StyleStory.provide(props.controls.Style, {
		Credits = e(SessionCreditsContext.Provider, {
			value = credits,
		}, {
			Effect = e(
				ParentComponent,
				{
					Size = UDim2.fromScale(1, 1),
					IsLoaded = props.controls.IsLoaded,
				} :: ParentComponent.Properties
			),
			Buttons = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.95),
				Size = UDim2.fromScale(0.6, 0.08),
			}, {
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0.05, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				GainSome = e(balanceButton, {
					LayoutOrder = 1,
					Text = `+25 Credits ({credits})`,
					[React.Event.Activated] = function()
						setCredits(credits + 25)
					end,
				}),
				GainMany = e(balanceButton, {
					LayoutOrder = 2,
					Text = "+1000 Credits",
					[React.Event.Activated] = function()
						setCredits(credits + 1000)
					end,
				}),
				Spend = e(balanceButton, {
					LayoutOrder = 3,
					Text = "-100 Credits",
					[React.Event.Activated] = function()
						setCredits(math.max(credits - 100, 0))
					end,
				}),
			}),
		}),
	})
end)
