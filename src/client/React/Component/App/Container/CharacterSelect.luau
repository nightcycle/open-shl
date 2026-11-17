--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local CharacterSelect = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterSelect")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
-- Types
export type Properties = {}
-- Constants
local ERROR_DURATION = 4
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local errorMessage: string?, setErrorMessage: (string?) -> () = useTimedState(ERROR_DURATION)
	local isMountedRef = useIsMounted()
	local isBusyRef = React.useRef(false)

	return e(
		CharacterSelect,
		{
			Size = UDim2.fromScale(1, 1),
			ErrorMessage = errorMessage,
			OnAction = function(action: CharacterSelect.ActionInfo)
				if action.Type == "Select" then
					if isBusyRef.current then
						return
					end
					isBusyRef.current = true
					setErrorMessage(nil)
					task.spawn(function()
						local selectRes = SessionService:SelectCharacter(action.CharacterId)
						isBusyRef.current = false
						if not isMountedRef.current or not ShellService.IsInitialized then
							return
						end
						if selectRes.IsErr then
							setErrorMessage(selectRes.Value)
							return
						end
						ShellService:FireTutorialTrigger("CharacterSelected")
						ShellService:CloseScreen()
					end)
				elseif action.Type == "Edit" then
					local screenRes = ShellService:OpenScreen({
						Type = "CharacterEditor",
						CharacterId = action.CharacterId,
					})
					if screenRes.IsErr then
						setErrorMessage(screenRes.Value)
					end
				elseif action.Type == "Exit" then
					ShellService:CloseScreen()
				end
			end,
		} :: CharacterSelect.Properties
	)
end
