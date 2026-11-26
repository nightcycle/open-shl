--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AppearanceUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local MenuDrawer = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/MenuDrawer")
-- Hooks
local useCharacterAttribute =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useCharacterAttribute")
local useIsFighting = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsFighting")
local useLocalCharacter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useLocalCharacter")
local usePeaceful = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePeaceful")
-- Contexts
local AppPanelContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/Panel")
local SessionActiveCharacterIdContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveCharacterId")
local SessionActiveIdentityKeyContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveIdentityKey")
local SessionCharactersContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Characters")
-- Types
local HUDTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/HUD/Types")
type Character = SessionCharactersContext.Character
type PanelId = AppPanelContext.PanelId
export type Properties = HUDTypes.Properties
-- Constants
-- the identity the powers are carried by, which is who the drawer calls the hero
local HERO_KEY: SessionActiveIdentityKeyContext.IdentityKey = "Main"
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- the slot a character is made in from scratch: the first one nobody was saved to yet, which is one whose hero has
-- no name. with none left it's the one that's played, made over
local function getNewCharacterId(characters: { Character }, activeCharacterId: string): string
	for _, character in characters do
		if character.Identities.Main.Profile.Name == "" then
			return character.Id
		end
	end
	return activeCharacterId
end

-- if the hero of the character that's played wears anything to take off
local function getIfMaskable(characters: { Character }, activeCharacterId: string): boolean
	for _, character in characters do
		if character.Id == activeCharacterId then
			return AppearanceUtil.getIfMaskable(character.Identities.Main.Appearance)
		end
	end
	return false
end
-- Class
-- the app tells every hud the same things, this one only has a use for where it's put + what's pressed. what the
-- old place kept on its buttons is kept here: whether the drawer is out
return function(props: Properties): React.ReactNode
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local isOpen: boolean, setIsOpen: (boolean) -> () = React.useState(false)
	local panel: PanelId? = React.useContext(AppPanelContext) :: PanelId?
	local characters = React.useContext(SessionCharactersContext)
	local activeCharacterId = React.useContext(SessionActiveCharacterIdContext)
	local identityKey = React.useContext(SessionActiveIdentityKeyContext)
	local avatar = useLocalCharacter()
	local isPeaceful, setPeaceful = usePeaceful()
	local isFighting = useIsFighting()
	-- what the server wrote onto the avatar: the mask is only ever asked for, never taken off here
	local isMasked = useCharacterAttribute(AttributeDefinition.IsMasked)
	local isHero = avatar ~= nil and identityKey == HERO_KEY
	local isMaskable = React.useMemo(function(): boolean
		return getIfMaskable(characters, activeCharacterId)
	end, { characters :: any, activeCharacterId })

	local dead = React.useMemo(function(): { [MenuDrawer.ActionType]: boolean }
		local out: { [MenuDrawer.ActionType]: boolean } = {
			-- only the hero has a mask, + only one that wears something on their head has it to take off: the old
			-- button did nothing without a hat
			ToggleMask = not isHero or not isMaskable,
			-- whoever is in a fight doesn't get to walk off as somebody else: the saves + the creator are menus the
			-- server keeps them out of until it's over
			Saves = isFighting,
			NewCharacter = isFighting,
		}
		table.freeze(out)
		return out
	end, { isFighting, isHero, isMaskable })

	return e(
		MenuDrawer,
		{
			Size = props.Size,
			ZIndex = props.ZIndex,
			IsOpen = isOpen,
			IsShopOpen = panel == "Shop",
			IsHero = if avatar then identityKey == HERO_KEY else nil,
			IsPeaceful = isPeaceful,
			Dead = dead,
			OnAction = function(action: MenuDrawer.ActionInfo)
				if action.Type == "Toggle" then
					setIsOpen(not isOpen)
				elseif action.Type == "Swap" then
					props.OnClick(PseudoEnum.MenuId.Swap)
				elseif action.Type == "ToggleMode" then
					setPeaceful(not isPeaceful)
				elseif action.Type == "ToggleMask" then
					-- the words on the button never say which way it goes, as they never did
					NetworkService:Fire(RemoteDefinition.SetMasked, not isMasked)
				elseif action.Type == "Reset" then
					-- what the reset of the engine's own menu does: the avatar is the player's to give up, the
					-- server brings the next one in
					local humanoid = avatar and avatar:FindFirstChildOfClass("Humanoid")
					if humanoid then
						humanoid.Health = 0
					end
				elseif action.Type == "NewCharacter" then
					-- a dead avatar has to get up before somebody else is made in its place
					if not avatar or AttributeDefinition.get(avatar, AttributeDefinition.IsDead) then
						return
					end
					local characterId = getNewCharacterId(characters, activeCharacterId)
					if characterId == "" then
						return
					end
					local screenRes = ShellService:OpenScreen({
						Type = "CharacterEditor",
						CharacterId = characterId,
					})
					if screenRes.IsErr then
						warn(`new character err: {screenRes.Value}`)
					end
				elseif action.Type == "Saves" then
					-- the drawer makes way for the list it leads to
					setIsOpen(false)
					props.OnClick(PseudoEnum.MenuId.Characters)
				elseif action.Type == "Shop" then
					props.OnClick(PseudoEnum.MenuId.Shop)
				end
			end,
		} :: MenuDrawer.Properties
	)
end
