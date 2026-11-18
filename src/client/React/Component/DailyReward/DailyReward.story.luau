--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local AppBootPhaseContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/BootPhase")
-- Types
type BootPhase = AppBootPhaseContext.BootPhase
type DailyReward = ParentComponent.DailyReward
-- Constants
local BOOT_PHASES: { BootPhase } = { "Playing", "Loading", "Intro" }
-- only a game that hands one out has it to show
local DAILY_REWARD = assert(ProductDefinition.DAILY_REWARD, `this game has no daily reward`)
local REWARD: DailyReward = table.freeze({
	Currency = DAILY_REWARD.CURRENCY,
	Amount = DAILY_REWARD.AMOUNT,
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
		BootPhase = UILabs.Choose(BOOT_PHASES),
	},
}, function(props)
	local reward: DailyReward?, setReward: (DailyReward?) -> () = React.useState(REWARD :: DailyReward?)

	return e(AppBootPhaseContext.Provider, {
		value = props.controls.BootPhase :: BootPhase,
	}, {
		Popup = e(
			ParentComponent,
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				Reward = reward,
				OnAction = function(action: ParentComponent.ActionInfo)
					if action.Type == "Dismiss" then
						setReward(nil)
					end
				end,
				SizeConstraint = Enum.SizeConstraint.RelativeXY,
			} :: ParentComponent.Properties
		),
		Grant = not reward and e("TextButton", {
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundColor3 = Color3.fromRGB(107, 107, 107),
			BorderSizePixel = 0,
			FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
			Position = UDim2.fromScale(0.5, 0.95),
			Size = UDim2.fromScale(0.2, 0.08),
			Text = "Grant the Reward",
			TextColor3 = Color3.new(1, 1, 1),
			TextScaled = true,
			[React.Event.Activated] = function()
				setReward(REWARD)
			end,
		}),
	})
end)
