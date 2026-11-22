--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local TeamChange = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/TeamChange")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
-- Contexts
-- Types
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the old place had the client look at how many are on each side + tell the server what it's on now. here it only
-- asks: the server says if the sides allow it, takes the avatar that's out down for it + answers with the side it's
-- on from then, or with the line that's read in place of the question
return function(): React.ReactNode
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	-- the panel is mounted as it opens, so the question is asked anew every time
	local refusal: string?, setRefusal: (string?) -> () = React.useState(nil :: string?)
	local isLeaving, setIsLeaving = React.useState(false)
	local isBusyRef = React.useRef(false)
	local isMountedRef = useIsMounted()

	local function ask()
		-- the server answers one ask at a time, a second one would only be turned down
		if isBusyRef.current then
			return
		end
		isBusyRef.current = true
		task.spawn(function()
			local teamRes = NetworkService:Invoke(RemoteDefinition.ChangeTeam, nil)
			if not isMountedRef.current then
				return
			end
			if teamRes.IsErr then
				isBusyRef.current = false
				setRefusal(teamRes.Value)
				return
			end
			-- the avatar is on its way down already, the panel has nothing left to ask
			setIsLeaving(true)
		end)
	end

	return e(
		TeamChange,
		{
			Size = UDim2.fromScale(1, 1),
			Refusal = refusal,
			IsLeaving = isLeaving,
			OnAction = function(action: TeamChange.ActionInfo)
				if action.Type == "Confirm" then
					ask()
				elseif action.Type == "Exit" then
					ShellService:ClosePanel("TeamChange")
				end
			end,
		} :: TeamChange.Properties
	)
end
