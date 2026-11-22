--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ServerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Server")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local ServerBrowser = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ServerBrowser")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
-- Contexts
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Listing = ServerDefinition.Listing
export type Properties = {}
-- Constants
local NO_LISTINGS: { Listing } = table.freeze({})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local listings: { Listing }, setListings: ({ Listing }) -> () = React.useState(NO_LISTINGS)
	local isBusy, setIsBusy = React.useState(false)
	local notice: string?, setNotice: (string?) -> () = React.useState(nil :: string?)
	-- a try is sent between two renders, so whether one is on its way is kept where it's current right away
	local isBusyRef = React.useRef(false)
	local isMountedRef = useIsMounted()

	local function comeBack(message: string)
		isBusyRef.current = false
		setIsBusy(false)
		setNotice(message)
	end

	local function refresh()
		task.spawn(function()
			local res = NetworkService:Invoke(RemoteDefinition.GetServers, nil)
			if not isMountedRef.current then
				return
			end
			if res.IsErr then
				setNotice(res.Value)
				return
			end
			setListings(res.Value)
		end)
	end

	-- on a yes nothing but the background is left until the teleport takes the player away
	local function send(invoke: () -> Result<true, string>)
		if isBusyRef.current then
			return
		end
		isBusyRef.current = true
		setIsBusy(true)
		setNotice(nil)
		task.spawn(function()
			local res = invoke()
			if isMountedRef.current and res.IsErr then
				comeBack(res.Value)
			end
		end)
	end

	React.useEffect(function()
		refresh()
		-- the server let the teleport through, it fell over later
		local connection = NetworkService:Connect(RemoteDefinition.TeleportFailed, function(message: string)
			if isBusyRef.current then
				comeBack(message)
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	return e(
		ServerBrowser,
		{
			Size = UDim2.fromScale(1, 1),
			Listings = listings,
			IsBusy = isBusy,
			Notice = notice,
			-- a name the filter can't be asked about stays as typed, the server has the last word when it's handed in
			FilterText = function(text: string): string
				local res = SessionService:FilterText(text)
				return if res.IsOk then res.Value else text
			end,
			OnAction = function(action: ServerBrowser.ActionInfo)
				if action.Type == "Back" then
					ShellService:SetServerBrowserOpen(false)
				elseif action.Type == "Refresh" then
					setNotice(nil)
					refresh()
				elseif action.Type == "Create" then
					local settings = action.Settings
					send(function(): Result<true, string>
						return NetworkService:Invoke(RemoteDefinition.CreateServer, settings)
					end)
				elseif action.Type == "Join" then
					local entry = action.Entry
					send(function(): Result<true, string>
						return NetworkService:Invoke(RemoteDefinition.JoinServer, entry)
					end)
				end
			end,
		} :: ServerBrowser.Properties
	)
end
