--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local ItemConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local ArtifactMenu = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ArtifactMenu")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local ItemDefSelection =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Selection/AppearanceItemDefinition")
local PreviewCharacterContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Preview")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type Character = SessionService.Character
type Appearance = AppearanceType.Appearance
type ItemDefinition = ArtifactMenu.ItemDefinition
type HiddenTag = ArtifactMenu.HiddenTag
export type Properties = {}
-- Constants
local ARTIFACT_CATEGORY = "artifacts"
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function getIfArtifact(definitionId: string): boolean
	local itemDefIndexRes = ItemAppearanceDefinition.getIndex(definitionId)
	return itemDefIndexRes.IsOk and itemDefIndexRes.Value.Category == ARTIFACT_CATEGORY
end

-- a hero wears one artifact at most, a new one takes the place of the last
local function wear(appearance: Appearance, definitionId: string)
	for i = #appearance.Items, 1, -1 do
		if getIfArtifact(appearance.Items[i].DefinitionId) then
			table.remove(appearance.Items, i)
		end
	end
	table.insert(appearance.Items, ItemConstructor.new(definitionId))
end

-- whatever the artifact hid shows again once it's off
local function takeOff(appearance: Appearance, definitionId: string)
	for i = #appearance.Items, 1, -1 do
		if appearance.Items[i].DefinitionId == definitionId then
			table.remove(appearance.Items, i)
		end
	end
	table.clear(appearance.HiddenTags)
end

local function setTagVisibility(appearance: Appearance, tag: HiddenTag, isVisible: boolean)
	local index = table.find(appearance.HiddenTags, tag)
	if isVisible and index then
		table.remove(appearance.HiddenTags, index)
	elseif not isVisible and not index then
		table.insert(appearance.HiddenTags, tag)
	end
end

-- artifacts are only ever worn by the super identity
local function newCharacter(character: Character, fn: (appearance: Appearance) -> ()): Character
	return FreezeUtil.delta(character, function(t: Character): Character
		fn(t.Identities.Main.Appearance)
		return t
	end)
end
-- Class
return function(): React.ReactNode
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local activeCharacter = React.useContext(CharacterContext)
	local selectedItemDef: ItemDefinition?, setSelectedItemDef: (ItemDefinition?) -> () =
		React.useState(nil :: ItemDefinition?)
	local unsavedCharacter: Character?, setUnsavedCharacter: (Character?) -> () = React.useState(nil :: Character?)
	local unsavedCharacterRef: { current: Character? } = React.useRef(nil :: Character?)
	local isSavingRef = React.useRef(false)
	local isMountedRef = useIsMounted()

	local character = if unsavedCharacter and unsavedCharacter.Id == activeCharacter.Id
		then unsavedCharacter
		else activeCharacter
	local previewCharacter = React.useMemo(function(): Character?
		if not selectedItemDef then
			return nil
		end
		for _, item in character.Identities.Main.Appearance.Items do
			if item.DefinitionId == selectedItemDef.Id then
				return nil
			end
		end
		return newCharacter(character, function(appearance: Appearance)
			wear(appearance, selectedItemDef.Id)
		end)
	end, { character :: any, selectedItemDef })

	-- the newest the hero is known to be, a render may still be behind it
	local function getCharacter(): Character?
		if unsavedCharacterRef.current then
			return unsavedCharacterRef.current
		end
		local characterOpt = SessionService:GetActiveCharacter()
		return if characterOpt.IsSome then characterOpt.Value else nil
	end

	local function save(newestCharacter: Character)
		unsavedCharacterRef.current = newestCharacter
		setUnsavedCharacter(newestCharacter)
		if isSavingRef.current then
			return
		end
		isSavingRef.current = true
		-- one save is out at a time, what the player changed in the meantime follows as one more
		task.spawn(function()
			while true do
				local sentCharacter = unsavedCharacterRef.current
				if not sentCharacter or not SessionService.IsInitialized then
					break
				end
				local saveRes = SessionService:SaveCharacter(sentCharacter)
				if saveRes.IsErr then
					-- the server keeps what it had, so does the menu
					warn(`save err: {saveRes.Value}`)
					unsavedCharacterRef.current = nil
					break
				end
				if unsavedCharacterRef.current == sentCharacter then
					unsavedCharacterRef.current = nil
					break
				end
			end
			isSavingRef.current = false
			if isMountedRef.current then
				setUnsavedCharacter(nil)
			end
		end)
	end

	local function edit(fn: (appearance: Appearance) -> ())
		local newestCharacter = getCharacter()
		if not newestCharacter then
			return
		end
		save(newCharacter(newestCharacter, fn))
	end

	return e(CharacterContext.Provider, {
		value = character,
	}, {
		PreviewCharacter = e(PreviewCharacterContext.Provider, {
			value = previewCharacter,
		}, {
			ItemDefSelection = e(ItemDefSelection.Provider, {
				value = selectedItemDef,
			}, {
				ArtifactMenu = e(
					ArtifactMenu,
					{
						Size = UDim2.fromScale(1, 1),
						OnAction = function(action: ArtifactMenu.ActionInfo)
							if action.Type == "SelectItem" then
								setSelectedItemDef(action.ItemDefinition)
							elseif action.Type == "AddItem" then
								local definitionId = action.ItemDefinition.Id
								edit(function(appearance: Appearance)
									wear(appearance, definitionId)
								end)
							elseif action.Type == "RemoveItem" then
								local definitionId = action.ItemDefinition.Id
								edit(function(appearance: Appearance)
									takeOff(appearance, definitionId)
								end)
							elseif action.Type == "SetTagVisibility" then
								local tag: HiddenTag, isVisible = action.Tag, action.IsVisible
								edit(function(appearance: Appearance)
									setTagVisibility(appearance, tag, isVisible)
								end)
							elseif action.Type == "Exit" then
								ShellService:CloseScreen()
							end
						end,
					} :: ArtifactMenu.Properties
				),
			}),
		}),
	})
end
