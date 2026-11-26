--!strict
--!native
-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AccessDefinition = require("@game/ReplicatedStorage/Shared/Definition/Access")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local RollUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/Roll")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
local usePeaceful = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePeaceful")
local usePlayerAttribute = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayerAttribute")
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
local AppScreenContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/Screen")
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local SessionCharactersContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Characters")
local SessionOwnedContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Owned")
-- Types
local EditorTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterEditor/Types")
type Character = SessionService.Character
type FilteredText = EditorTypes.FilteredText
type EntitlementKey = ProductDefinition.EntitlementKey
type Layout = EditorTypes.Component
type Owned = SessionOwnedContext.Owned
type ProductDefinition = ProductDefinition.ProductDefinition
export type Properties = {}
-- Constants
local ERROR_DURATION = 4
local IS_STUDIO = RunService:IsStudio()
-- what the passes of the game hand out. the list is the game's + never changes, so each is read by a hook of its own
local ENTITLEMENT_KEYS: { EntitlementKey } = ProductDefinition.listEntitlements()
-- only a game with a group to be in has anybody to ask about it
local HAS_PROMO = GameDefinition.FEATURES.Promo
-- where what's behind a pass is had for a fee, a draft is handed in to be stored, paid for + played in one. cash is
-- what that's paid in, so the shop of the game can be put up over its editor
local HAS_RENT = GameDefinition.FEATURES.Rent
local Shop: (() -> React.ReactNode)? = if HAS_RENT
	then require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/Shop")
	else nil
-- only one game ever dealt a character: its editor rolls the draft anew at a press
local IS_RANDOMIZABLE = GameDefinition.tune(false, { shl3 = true })
-- how the editor is laid out is the game's own, the layout of another game is never required
local CharacterEditor: Layout = GameDefinition.pick({
	shl1 = function(): Layout
		return require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard")
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

-- the lot of a currency that covers what a player is short of with the least to spare, the largest one where none
-- does (the old place prompted nothing then, so its dearest power couldn't be paid for out of the editor)
local function getCoveringProduct(currency: string, shortfall: number): ProductDefinition?
	local covering: ProductDefinition? = nil
	local largest: ProductDefinition? = nil
	local coveringAmount, largestAmount = math.huge, 0
	for _, definition in ProductDefinition.list() do
		local grant = definition.Grant
		if grant.Type ~= "Currency" or grant.Currency ~= currency then
			continue
		end
		if grant.Amount >= shortfall and grant.Amount < coveringAmount then
			covering, coveringAmount = definition, grant.Amount
		end
		if grant.Amount > largestAmount then
			largest, largestAmount = definition, grant.Amount
		end
	end
	return covering or largest
end

-- yields in studio, where a lot is handed over for free the way the shop has it. anywhere else the engine asks the
-- player, the server hears of it from the receipt
local function promptProduct(definition: ProductDefinition): boolean
	if IS_STUDIO then
		return NetworkService.IsInitialized
			and NetworkService:Invoke(RemoteDefinition.PurchaseProduct, definition.Id).IsOk
	end
	return (pcall(function()
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, definition.LegacyId)
	end))
end

-- yields in studio, where a pass is handed over for free the way a lot is. anywhere else the engine asks the player,
-- for the game pass or for the asset a pass from before there were game passes is sold as. the server hears how it
-- went + the player wears what the pass hands out once it's theirs
local function promptPass(definition: ProductDefinition): boolean
	if IS_STUDIO then
		return NetworkService.IsInitialized
			and NetworkService:Invoke(RemoteDefinition.PurchaseProduct, definition.Id).IsOk
	end
	local id, isAsset = ProductDefinition.getPassPrompt(definition)
	return (
		pcall(function()
			if isAsset then
				MarketplaceService:PromptPurchase(Players.LocalPlayer, id)
			else
				MarketplaceService:PromptGamePassPurchase(Players.LocalPlayer, id)
			end
		end)
	)
end

-- everything the player has of what the game holds back: what the session says was bought + what opens a lock, which
-- the server writes onto the player
local function useOwned(): Owned
	local owned = React.useContext(SessionOwnedContext)
	local entitlements: { EntitlementKey } = {}
	for _, key: EntitlementKey in ENTITLEMENT_KEYS do
		if usePlayerAttribute(AttributeDefinition.fromEntitlement(key)) then
			table.insert(entitlements, key)
		end
	end
	local hasGroupPerk = usePlayerAttribute(AttributeDefinition.HasGroupPerk)
	local entitlementText = table.concat(entitlements, ",")
	return React.useMemo(function(): Owned
		return table.freeze({
			ItemIds = owned.ItemIds,
			PowerIds = owned.PowerIds,
			Entitlements = table.freeze(entitlements),
			HasGroupPerk = hasGroupPerk,
		})
	end, { owned :: any, entitlementText :: any, hasGroupPerk :: any })
end
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
	local isShopOpen, setIsShopOpen = React.useState(false)
	local filteredText: FilteredText?, setFilteredText: (FilteredText?) -> () = React.useState(nil :: FilteredText?)
	-- what the server dealt at the last press of randomize, as the draft it was dealt into
	local rolled: Character?, setRolled: (Character?) -> () = React.useState(nil :: Character?)
	local isMountedRef = useIsMounted()
	local isBusyRef = React.useRef(false)
	-- whether the layout last asked for its player to sit fights out, nil for one that never asks
	local isPeacefulRef = React.useRef(nil :: boolean?)
	local isPeaceful, setPeaceful = usePeaceful()
	local owned = useOwned()

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

	local editor = e(CharacterContext.Provider, {
		value = character,
	}, {
		CharacterEditor = e(
			CharacterEditor,
			{
				Size = UDim2.fromScale(1, 1),
				ErrorMessage = errorMessage,
				IsSaving = isSaving,
				-- left out for one who fights, which is everybody in a game where that's no pick
				IsPeaceful = if isPeaceful then true else nil,
				IsShopOpen = if isShopOpen then true else nil,
				FilteredText = filteredText,
				IsRandomizable = if IS_RANDOMIZABLE then true else nil,
				-- a roll is for the slot it was asked for, the editor of another one starts from what's stored
				Draft = if rolled and rolled.Id == character.Id then rolled else nil,
				OnAction = function(action: EditorTypes.ActionInfo)
					if action.Type == "Save" then
						if isBusyRef.current then
							return
						end
						isBusyRef.current = true
						setIsSaving(true)
						setErrorMessage(nil)
						local draft = action.Character
						local isPeacefulAsked = isPeacefulRef.current
						task.spawn(function()
							local saveRes = if HAS_RENT
								then SessionService:RentCharacter(draft)
								else SessionService:SaveCharacter(draft)
							local errorLine: string? = if saveRes.IsErr then saveRes.Value else nil
							-- the player leaves the editor as the character they saved, which a draft that's rented for is
							-- already
							if
								not HAS_RENT
								and saveRes.IsOk
								and isMountedRef.current
								and SessionService.IsInitialized
							then
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
							-- the mode that was picked with the character goes into the game with it
							if isPeacefulAsked ~= nil then
								setPeaceful(isPeacefulAsked)
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
					elseif action.Type == "Randomize" then
						if isBusyRef.current then
							return
						end
						isBusyRef.current = true
						setErrorMessage(nil)
						local draft = action.Character
						task.spawn(function()
							local rollRes = SessionService:RollCharacter(draft.Id)
							isBusyRef.current = false
							if not isMountedRef.current then
								return
							end
							if rollRes.IsErr then
								setErrorMessage(rollRes.Value)
								return
							end
							-- nothing is stored until the editor saves, leaving it drops the roll with the draft
							setRolled(RollUtil.merge(draft, rollRes.Value))
						end)
					elseif action.Type == "Purchase" then
						local access = AccessDefinition.getAccess(action.Id)
						-- what's behind a pass is got by getting the pass
						if access.Type == "Entitlement" then
							local passRes = ProductDefinition.getFromEntitlement(access.Key)
							if isBusyRef.current or passRes.IsErr then
								return
							end
							isBusyRef.current = true
							setErrorMessage(nil)
							local pass = passRes.Value
							task.spawn(function()
								local isPrompted = promptPass(pass)
								isBusyRef.current = false
								if isMountedRef.current and not isPrompted then
									setErrorMessage(`"{pass.Name}" can't be bought right now`)
								end
							end)
							return
						end
						if isBusyRef.current or access.Type ~= "Price" then
							return
						end
						isBusyRef.current = true
						setErrorMessage(nil)
						local id = action.Id
						local balance = AttributeDefinition.get(
							Players.LocalPlayer,
							AttributeDefinition.fromCurrency(access.Currency)
						)
						-- whoever is short is offered the lot that covers it instead, as the old editor did
						local product = if balance < access.Amount
							then getCoveringProduct(access.Currency, access.Amount - balance)
							else nil
						task.spawn(function()
							local errorLine: string? = nil
							if product then
								local currencyName = ProductDefinition.getCurrencyName(access.Currency)
								errorLine = if promptProduct(product) then nil else `not enough {currencyName}`
							else
								local purchaseRes = SessionService:PurchaseItem(id)
								errorLine = if purchaseRes.IsErr then purchaseRes.Value else nil
							end
							isBusyRef.current = false
							if isMountedRef.current and errorLine then
								setErrorMessage(errorLine)
							end
						end)
					elseif action.Type == "CheckGroupPerk" then
						-- nobody waits for the answer: what it opens is written onto the player once the server knows
						if HAS_PROMO and NetworkService.IsInitialized then
							task.spawn(function()
								NetworkService:Invoke(RemoteDefinition.CheckGroupPerk, nil)
							end)
						end
					elseif action.Type == "ToggleShop" then
						setIsShopOpen(not isShopOpen)
					elseif action.Type == "SetPeaceful" then
						isPeacefulRef.current = action.IsPeaceful
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
	-- the editor reads what's the player's off one place, the locks that are open to them among it
	return e(SessionOwnedContext.Provider, {
		value = owned,
	}, {
		Editor = editor,
		-- the shell puts a panel up over the game alone, so over the editor the shop is the editor's own to put up
		Shop = isShopOpen and Shop and e("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 2,
		}, {
			Shop = e(Shop, {}),
		}),
	})
end
