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
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local AppBootPhaseContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/BootPhase")
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local SessionGemsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Gems")
-- Types
type BootPhase = AppBootPhaseContext.BootPhase
-- Constants
local BOOT_PHASES: { BootPhase } = { "Playing", "Loading", "Intro" }
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
		BootPhase = UILabs.Choose(BOOT_PHASES),
	},
}, function(props)
	local credits, setCredits = React.useState(ProductDefinition.STARTING_BALANCES.Credits)
	local gems, setGems = React.useState(ProductDefinition.STARTING_BALANCES.Gems)

	return e(AppBootPhaseContext.Provider, {
		value = props.controls.BootPhase :: BootPhase,
	}, {
		Credits = e(SessionCreditsContext.Provider, {
			value = credits,
		}, {
			Gems = e(SessionGemsContext.Provider, {
				value = gems,
			}, {
				Popup = e(
					ParentComponent,
					{
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
						IsLoaded = props.controls.IsLoaded,
						SizeConstraint = Enum.SizeConstraint.RelativeXY,
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
					GainCredits = e(balanceButton, {
						LayoutOrder = 1,
						Text = `+25 Credits ({credits})`,
						[React.Event.Activated] = function()
							setCredits(credits + 25)
						end,
					}),
					GainGems = e(balanceButton, {
						LayoutOrder = 2,
						Text = `+5 Gems ({gems})`,
						[React.Event.Activated] = function()
							setGems(gems + 5)
						end,
					}),
					SpendCredits = e(balanceButton, {
						LayoutOrder = 3,
						Text = "-100 Credits",
						[React.Event.Activated] = function()
							setCredits(math.max(credits - 100, 0))
						end,
					}),
				}),
			}),
		}),
	})
end)
