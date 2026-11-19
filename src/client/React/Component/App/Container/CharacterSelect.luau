--!strict
--!native
-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
-- Types
local CharacterSelectTypes =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterSelect/Types")
type Character = SessionService.Character
type Layout = CharacterSelectTypes.Component
type ProductDefinition = ProductDefinition.ProductDefinition
export type Properties = {}
-- Constants
local ERROR_DURATION = 4
-- a pass is free in studio, the server hands it over. anywhere else it's paid for through the prompt of the engine
local IS_STUDIO = RunService:IsStudio()
-- how the screen is laid out is the game's own, the layout of another game is never required
local Layout: Layout = GameDefinition.pick({
	shl1 = function(): Layout
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/SaveSlots")
	end,
	shl2 = function(): Layout
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterSelect")
	end,
	shl3 = function(): Layout
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/SuitManager")
	end,
})
assert(CharacterSelectTypes.Component(Layout))
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- the pass that adds slots, a game that sells none has nothing to ask for
local function getSlotPass(): ProductDefinition?
	for _, definition in ProductDefinition.list() do
		local grant = definition.Grant
		if grant.Type == "Entitlement" and grant.Key == "ExtraCharacterSlots" then
			return definition
		end
	end
	return nil
end
-- Class
return function(): React.ReactNode
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local errorMessage: string?, setErrorMessage: (string?) -> () = useTimedState(ERROR_DURATION)
	local isMountedRef = useIsMounted()
	local isBusyRef = React.useRef(false)
	local isBuyingRef = React.useRef(false)

	return e(
		Layout,
		{
			Size = UDim2.fromScale(1, 1),
			ErrorMessage = errorMessage,
			OnAction = function(action: CharacterSelectTypes.ActionInfo)
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
				elseif action.Type == "BuySlots" then
					local definition = getSlotPass()
					if not definition then
						setErrorMessage(`no pass adds a slot`)
						return
					end
					if IS_STUDIO then
						-- one purchase at a time, a button that's hammered doesn't pile them up
						if isBuyingRef.current then
							return
						end
						assert(NetworkService.IsInitialized, `the network service isn't initialized`)
						isBuyingRef.current = true
						task.spawn(function()
							local purchaseRes = NetworkService:Invoke(RemoteDefinition.PurchaseProduct, definition.Id)
							isBuyingRef.current = false
							if not isMountedRef.current then
								return
							end
							if purchaseRes.IsErr then
								setErrorMessage(purchaseRes.Value)
							else
								setErrorMessage(nil)
							end
						end)
						return
					end
					-- what was paid for isn't the business of the client: the server is told by the engine + the slots
					-- show up once the pass is granted
					local isPrompted = pcall(function()
						MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, definition.LegacyId)
					end)
					if isPrompted then
						setErrorMessage(nil)
					else
						setErrorMessage(`"{definition.Name}" can't be bought right now`)
					end
				elseif action.Type == "Copy" then
					if isBusyRef.current then
						return
					end
					local activeOpt = SessionService:GetActiveCharacter()
					if activeOpt.IsNone then
						setErrorMessage(`nobody is played`)
						return
					end
					local characterId = action.CharacterId
					-- whoever is played is kept in their own slot already
					if activeOpt.Value.Id == characterId then
						return
					end
					isBusyRef.current = true
					setErrorMessage(nil)
					-- the same character under the name of another slot: the server stores it there like any edit
					local copy = FreezeUtil.delta(activeOpt.Value, function(t: Character): Character
						t.Id = characterId
						return t
					end)
					task.spawn(function()
						local saveRes = SessionService:SaveCharacter(copy)
						isBusyRef.current = false
						if not isMountedRef.current then
							return
						end
						if saveRes.IsErr then
							setErrorMessage(saveRes.Value)
						end
					end)
				elseif action.Type == "Exit" then
					ShellService:CloseScreen()
				end
			end,
		} :: CharacterSelectTypes.Properties
	)
end
