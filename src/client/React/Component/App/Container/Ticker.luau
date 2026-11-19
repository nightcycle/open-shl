--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Components
local Ticker = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Ticker")
-- Hooks
-- Contexts
local AppIsGameplayHudVisibleContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsGameplayHudVisible")
-- Types
export type Properties = {}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Ticker/CONSTANTS")
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the news is read with the hud + gone with it: a menu that fills the screen has no bar over it. it starts over
-- from its first line every time it's back
return function(): React.ReactNode
	local isGameplayHudVisible = React.useContext(AppIsGameplayHudVisibleContext)
	if not isGameplayHudVisible then
		return nil
	end
	return e(
		Ticker,
		{
			Size = UDim2.fromScale(1, 1),
			Messages = CONSTANTS.MESSAGES,
		} :: Ticker.Properties
	)
end
