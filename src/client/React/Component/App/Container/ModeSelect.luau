--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ServerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Server")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local ModeSelect = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ModeSelect")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
-- Contexts
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Mode = ServerDefinition.Mode
export type Properties = {}
-- Constants
-- how long the buttons take to slide off, the choice is acted on once they're gone
local LEAVE_DURATION = 1
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local isLeaving, setIsLeaving = React.useState(false)
	local notice: string?, setNotice: (string?) -> () = React.useState(nil :: string?)
	local idNotice: string?, setIdNotice: (string?) -> () = React.useState(nil :: string?)
	-- a choice is acted on between two renders, so whether one is on its way is kept where it's current right away
	local isBusyRef = React.useRef(false)
	local isMountedRef = useIsMounted()

	local function comeBack(message: string)
		isBusyRef.current = false
		setIsLeaving(false)
		setNotice(message)
	end

	React.useEffect(function()
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

	local function selectMode(mode: Mode)
		if isBusyRef.current then
			return
		end
		isBusyRef.current = true
		setNotice(nil)
		setIsLeaving(true)
		task.delay(LEAVE_DURATION, function()
			if not isMountedRef.current then
				return
			end
			-- the mode of this place is played right here
			if mode == BUILD_CONFIG.MODE then
				ShellService:FinishBootPhase("ModeSelect")
				return
			end
			local res = NetworkService:Invoke(RemoteDefinition.SelectMode, mode)
			-- on a yes the screen stays empty until the teleport takes the player away
			if isMountedRef.current and res.IsErr then
				comeBack(res.Value)
			end
		end)
	end

	local function joinById(id: string)
		if isBusyRef.current then
			return
		end
		isBusyRef.current = true
		setNotice(nil)
		setIdNotice(nil)
		task.spawn(function()
			local res = NetworkService:Invoke(RemoteDefinition.JoinServerById, id)
			if not isMountedRef.current then
				return
			end
			if res.IsErr then
				isBusyRef.current = false
				setIdNotice(res.Value)
				return
			end
			setIsLeaving(true)
		end)
	end

	return e(
		ModeSelect,
		{
			Size = UDim2.fromScale(1, 1),
			IsLeaving = isLeaving,
			Notice = notice,
			IdNotice = idNotice,
			OnAction = function(action: ModeSelect.ActionInfo)
				if action.Type == "ModePressed" then
					selectMode(action.Mode)
				elseif action.Type == "IdEntered" then
					joinById(action.Id)
				elseif action.Type == "ServersPressed" then
					if not isBusyRef.current then
						ShellService:SetServerBrowserOpen(true)
					end
				end
			end,
		} :: ModeSelect.Properties
	)
end
