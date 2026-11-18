--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
local AppScreenContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/Screen")
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local SessionCharactersContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Characters")
-- Types
local EditorTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterEditor/Types")
type Character = SessionService.Character
type FilteredText = EditorTypes.FilteredText
type Layout = EditorTypes.Component
export type Properties = {}
-- Constants
local ERROR_DURATION = 4
-- how the editor is laid out is the game's own, the layout of another game is never required
local CharacterEditor: Layout = GameDefinition.pick({
	shl1 = function(): Layout
		error(`shl1 has no character editor yet`)
	end,
	shl2 = function(): Layout
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterEditor")
	end,
	shl3 = function(): Layout
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/TabbedEditor")
	end,
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local screen = React.useContext(AppScreenContext)
	local characterId = if screen.Type == "CharacterEditor" then screen.CharacterId else ""
	local characters = React.useContext(SessionCharactersContext)
	local character = React.useMemo(function(): Character?
		for _, slot in characters do
			if slot.Id == characterId then
				return slot
			end
		end
		return nil
	end, { characters :: any, characterId })

	local errorMessage: string?, setErrorMessage: (string?) -> () = useTimedState(ERROR_DURATION)
	local isSaving, setIsSaving = React.useState(false)
	local filteredText: FilteredText?, setFilteredText: (FilteredText?) -> () = React.useState(nil :: FilteredText?)
	local isMountedRef = useIsMounted()
	local isBusyRef = React.useRef(false)

	-- back to where the edit was asked for, the draft is dropped
	local function leave()
		local screenRes = ShellService:OpenScreen({
			Type = "CharacterSelect",
		})
		if screenRes.IsErr then
			warn(`screen err: {screenRes.Value}`)
			ShellService:CloseScreen()
		end
	end
	local hasCharacter = character ~= nil
	React.useEffect(function()
		-- there's nothing to edit when no slot holds the character the screen was opened with
		if not hasCharacter and ShellService.IsInitialized then
			leave()
		end
		return function() end
	end, { hasCharacter })
	if not character then
		return nil
	end

	return e(CharacterContext.Provider, {
		value = character,
	}, {
		CharacterEditor = e(
			CharacterEditor,
			{
				Size = UDim2.fromScale(1, 1),
				ErrorMessage = errorMessage,
				IsSaving = isSaving,
				FilteredText = filteredText,
				OnAction = function(action: EditorTypes.ActionInfo)
					if action.Type == "Save" then
						if isBusyRef.current then
							return
						end
						isBusyRef.current = true
						setIsSaving(true)
						setErrorMessage(nil)
						local draft = action.Character
						task.spawn(function()
							local saveRes = SessionService:SaveCharacter(draft)
							local errorLine: string? = if saveRes.IsErr then saveRes.Value else nil
							-- the player leaves the editor as the character they saved
							if saveRes.IsOk and isMountedRef.current and SessionService.IsInitialized then
								local selectRes = SessionService:SelectCharacter(draft.Id)
								errorLine = if selectRes.IsErr then selectRes.Value else nil
							end
							isBusyRef.current = false
							if not isMountedRef.current or not ShellService.IsInitialized then
								return
							end
							setIsSaving(false)
							if errorLine then
								setErrorMessage(errorLine)
								return
							end
							ShellService:CloseScreen()
						end)
					elseif action.Type == "FilterText" then
						local filter = action.Filter
						task.spawn(function()
							local filterRes = SessionService:FilterText(filter.Text)
							if not isMountedRef.current then
								return
							end
							if filterRes.IsErr then
								setErrorMessage(filterRes.Value)
								return
							end
							setFilteredText(table.freeze({
								Filter = filter,
								Text = filterRes.Value,
							}))
						end)
					elseif action.Type == "Back" then
						ShellService:FireTutorialTrigger("EditorBack")
					elseif action.Type == "Exit" then
						if not isBusyRef.current then
							leave()
						end
					end
				end,
			} :: EditorTypes.Properties
		),
	})
end
