--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
-- Components
local DailyReward = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/DailyReward")
-- Hooks
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
-- Types
type Reward = SessionService.DailyReward
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local reward = useSignalState(SessionService.DailyRewardGranted, function(): Reward?
		return SessionService:GetDailyReward()
	end)
	local dismissedReward: Reward?, setDismissedReward: (Reward?) -> () = React.useState(nil :: Reward?)

	return e(
		DailyReward,
		{
			Size = UDim2.fromScale(1, 1),
			Reward = if reward ~= dismissedReward then reward else nil,
			OnAction = function(action: DailyReward.ActionInfo)
				if action.Type == "Dismiss" then
					setDismissedReward(reward)
				end
			end,
		} :: DailyReward.Properties
	)
end
