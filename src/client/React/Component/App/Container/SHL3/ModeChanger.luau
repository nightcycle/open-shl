--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local ModeCards =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/SHL3/ModeCards")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local ModeChanger = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ModeChanger")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
-- Contexts
-- Types
local ServerType = require("@game/ReplicatedStorage/Shared/Type/Server")
type Mode = ServerType.Mode
-- why the last try at a place went nowhere
type Notice = {
	Mode: Mode,
	Text: string,
}
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the old place sent the id of a place to the server, which teleported whoever asked to whatever id that was + kept
-- trying for good. here a client names a mode: the server knows the place, tries a few times + says when it gives up.
-- a card that was pressed reads what the old one did until the player is gone, one that was turned down is back with
-- the line of the server on it, which is new: the old place had nothing to say
return function(): React.ReactNode
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	-- the panel is mounted as it opens, so every card starts out as it's written
	local leavingMode: Mode?, setLeavingMode: (Mode?) -> () = React.useState(nil :: Mode?)
	local notice: Notice?, setNotice: (Notice?) -> () = React.useState(nil :: Notice?)
	-- the mode that's asked for is kept where it's current right away: a press is acted on between two renders
	local busyModeRef = React.useRef(nil :: Mode?)
	local isMountedRef = useIsMounted()

	local function comeBack(text: string)
		-- a ref only knows it for a string
		local mode = busyModeRef.current :: Mode?
		if not mode then
			return
		end
		busyModeRef.current = nil
		setLeavingMode(nil)
		local nextNotice: Notice = {
			Mode = mode :: Mode,
			Text = text,
		}
		setNotice(nextNotice)
	end

	React.useEffect(function()
		-- the server let the teleport through, it fell over later
		local connection = NetworkService:Connect(RemoteDefinition.TeleportFailed, function(text: string)
			comeBack(text)
		end)
		return function()
			connection:Disconnect()
		end
	end, {})

	local function teleport(mode: Mode)
		-- the server answers one ask at a time, a second one would only be turned down
		if busyModeRef.current then
			return
		end
		busyModeRef.current = mode
		setLeavingMode(mode)
		setNotice(nil)
		task.spawn(function()
			local res = NetworkService:Invoke(RemoteDefinition.SelectMode, mode)
			-- on a yes the card goes on saying so until the teleport takes the player away
			if isMountedRef.current and res.IsErr then
				comeBack(res.Value)
			end
		end)
	end

	local cards: { ModeChanger.CardInfo } = {}
	for _, card in ModeCards do
		table.insert(cards, {
			Mode = card.Mode,
			Title = card.Title,
			Description = card.Description,
			IsLeaving = leavingMode == card.Mode,
			Notice = if notice and notice.Mode == card.Mode then notice.Text else nil,
		})
	end

	return e(
		ModeChanger,
		{
			Size = UDim2.fromScale(1, 1),
			Cards = cards,
			OnAction = function(action: ModeChanger.ActionInfo)
				if action.Type == "Teleport" then
					teleport(action.Mode)
				elseif action.Type == "Exit" then
					ShellService:ClosePanel("ModeChanger")
				end
			end,
		} :: ModeChanger.Properties
	)
end
