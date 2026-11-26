--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
-- Components
local AlertStrip = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/AlertStrip")
-- Hooks
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
-- Types
export type Properties = {}
-- Constants
-- seconds a line is up for from when it came in, the slide in is part of them
local HOLD_DURATION = 6
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- whoever is sent a line is shown it: who that is was the server's to pick, the old place sent every line to
-- everybody + had the client ask its own team. it's up over the menus as well. a line that comes in while one is up
-- takes its place + is up for as long as any, the old place had the first one's way out carry the second off early
return function(): React.ReactNode
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local text: string?, setText: (string?) -> () = useTimedState(HOLD_DURATION)
	React.useEffect(function()
		local connection = NetworkService:Connect(RemoteDefinition.Alert, function(value: string)
			setText(value)
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	return e(
		AlertStrip,
		{
			Size = UDim2.fromScale(1, 1),
			Text = text,
		} :: AlertStrip.Properties
	)
end
