--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
-- Components
local CurrencyPopup = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CurrencyPopup")
-- Hooks
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
-- Types
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	-- the balances are written before the session loads, so whatever they move by after that is a gain
	local isLoaded = useSignalState(SessionService.Loaded, function(): boolean
		return SessionService:GetIsLoaded()
	end)

	return e(
		CurrencyPopup,
		{
			Size = UDim2.fromScale(1, 1),
			IsLoaded = isLoaded,
		} :: CurrencyPopup.Properties
	)
end
