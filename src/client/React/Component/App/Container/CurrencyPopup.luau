--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
-- Components
-- Hooks
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
-- Types
local CurrencyPopupTypes =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CurrencyPopup/Types")
type Layout = CurrencyPopupTypes.Component
export type Properties = {}
-- Constants
-- how a gain is shown is the game's own, the layout of another game is never required
local Layout: Layout = GameDefinition.pick({
	shl1 = function(): Layout
		error(`shl1 has no currency popup yet`)
	end,
	shl2 = function(): Layout
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CurrencyPopup")
	end,
	shl3 = function(): Layout
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/MoneyEffect")
	end,
})
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
		Layout,
		{
			Size = UDim2.fromScale(1, 1),
			IsLoaded = isLoaded,
		} :: CurrencyPopupTypes.Properties
	)
end
