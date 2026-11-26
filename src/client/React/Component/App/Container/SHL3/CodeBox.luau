--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
-- Components
local CodeBox = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CodeBox")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
-- Contexts
local AppIsGameplayHudVisibleContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsGameplayHudVisible")
-- Types
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function box(): React.ReactNode
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local text, setText = React.useState("")
	local notice: string?, setNotice: (string?) -> () = React.useState(nil :: string?)
	-- the server answers one ask at a time, a second one would only be turned down
	local isBusyRef = React.useRef(false)
	local isMountedRef = useIsMounted()

	local function redeem(code: string)
		if isBusyRef.current then
			return
		end
		isBusyRef.current = true
		task.spawn(function()
			local res = NetworkService:Invoke(RemoteDefinition.RedeemCode, code)
			isBusyRef.current = false
			if not isMountedRef.current then
				return
			end
			-- the box is emptied either way. what a code paid shows where every gain does: off the balance, + as
			-- the money that pops up for it. what paid nothing leaves the line of the server in the box
			setText("")
			setNotice(if res.IsErr then res.Value else nil)
		end)
	end

	return e(
		CodeBox,
		{
			Size = UDim2.fromScale(1, 1),
			Text = text,
			Notice = notice,
			OnAction = function(action: CodeBox.ActionInfo)
				if action.Type == "Change" then
					setText(action.Text)
				elseif action.Type == "Focus" then
					setNotice(nil)
				elseif action.Type == "Submit" then
					redeem(action.Text)
				end
			end,
		} :: CodeBox.Properties
	)
end
-- Class
-- the old place had the client hold the table of codes, check if one was used + pay itself. here the box sends what
-- was typed + nothing else, the server says what comes of it. it's there with the hud, as it was: from the end of
-- the way in on, + away for every menu
return function(): React.ReactNode
	local isGameplayHudVisible = React.useContext(AppIsGameplayHudVisibleContext)
	if not isGameplayHudVisible then
		return nil
	end
	return e(box, {})
end
