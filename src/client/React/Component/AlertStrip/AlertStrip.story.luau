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
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
-- Types
-- Constants
-- what the town of the old place had to say, each to the side that's called on
local BANK_TEXT = "Villains are trying to rob the bank!"
local REFINERY_TEXT = "Villains are trying to blow up the refinery!"
local GRAVEYARD_TEXT = "Villains are trying to start a zombie apocalypse at the graveyard!"
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function alertButton(props: RobloxComponents.TextButtonProperties)
	return e(RobloxComponents.TextButton({
		BackgroundColor3 = Color3.fromRGB(107, 107, 107),
		BorderSizePixel = 0,
		FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
		Size = UDim2.fromScale(0.22, 1),
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
	}, props))
end
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl3"),
		-- seconds a line is up for from the press, the slide in is part of them
		HoldDuration = UILabs.Slider(6, 1, 12, 0.5),
	},
}, function(props)
	-- stands in for the container: a line that comes in while one is up takes its place + is up for as long
	local text: string?, setText: (string?) -> () = useTimedState(props.controls.HoldDuration)

	return StyleStory.provide(props.controls.Style, {
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			ClipsDescendants = true,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			Strip = e(
				ParentComponent,
				{
					Size = UDim2.fromScale(1, 1),
					Text = text,
				} :: ParentComponent.Properties
			),
			Buttons = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, 0.05),
				Size = UDim2.fromScale(0.8, 0.06),
			}, {
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					Padding = UDim.new(0.03, 0),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				Bank = e(alertButton, {
					LayoutOrder = 1,
					Text = "Bank",
					[React.Event.Activated] = function()
						setText(BANK_TEXT)
					end,
				}),
				Refinery = e(alertButton, {
					LayoutOrder = 2,
					Text = "Refinery",
					[React.Event.Activated] = function()
						setText(REFINERY_TEXT)
					end,
				}),
				Graveyard = e(alertButton, {
					LayoutOrder = 3,
					Text = "Graveyard",
					[React.Event.Activated] = function()
						setText(GRAVEYARD_TEXT)
					end,
				}),
				Park = e(alertButton, {
					LayoutOrder = 4,
					Text = "Park",
					[React.Event.Activated] = function()
						setText(nil)
					end,
				}),
			}),
		}),
	})
end)
