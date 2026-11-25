--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local CharacterEditorConstructor = require("@game/ReplicatedStorage/Shared/Constructor/CharacterEditor")
local CharacterEditorUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor")
local StateUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor/State")
-- Components
-- Hooks
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local CharacterEditorFieldCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldCallback")
local CharacterEditorRefusalContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/Refusal")
local CharacterEditorStateContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/State")
local CharacterEditorTextFilterCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/TextFilterCallback")
local IsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/IsHeroFocus")
local PathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/Path")
local PreviewCharacterContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Preview")
local SessionEntitlementsContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Entitlements")
local SessionPowerLimitContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/PowerLimit")
local SetIsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetIsHeroFocus")
local SetPathContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/SetPath")
-- Types
local EditorTypes = require("./Types")
type Character = CharacterEditorUtil.Character
type EditorState = CharacterEditorStateContext.EditorState
type Entitlements = CharacterEditorConstructor.Entitlements
type FieldDefinition = CharacterEditorFieldCallback.FieldDefinition
type FieldEdit = CharacterEditorFieldCallback.FieldEdit
type Refusal = CharacterEditorRefusalContext.Refusal
type EntitlementKey = SessionEntitlementsContext.EntitlementKey
type TextFilter = EditorTypes.TextFilter
type FilteredText = EditorTypes.FilteredText
export type Properties = {
	Draft: Character?, -- takes the place of the draft each time another one is handed in
	FilteredText: FilteredText?,
	OnFilterText: (filter: TextFilter) -> (),
	children: { [string]: React.ReactNode }?,
}
-- Constants
local MULTI_HAIR_KEY: EntitlementKey = "MultiHair"
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function applyFilteredText(state: EditorState, filteredText: FilteredText): EditorState
	local filter = filteredText.Filter
	if state.Path ~= filter.Path then
		return state
	end
	for _, field in CharacterEditorUtil.listFields(state) do
		-- a text is of the identity in focus unless its field names one: a page can hold the same text of each
		if
			field.Type ~= "Text"
			or field.Binding.Key ~= filter.Key
			or (field.Binding.IdentityKey or state.IdentityKey) ~= filter.IdentityKey
		then
			continue
		end
		local value = CharacterEditorUtil.read(state, field)
		if value.Type ~= "Text" or value.Text ~= filter.Text then
			return state
		end
		local stateRes = CharacterEditorUtil.write(state, field, {
			Type = "Text",
			Text = filteredText.Text,
		})
		if stateRes.IsErr then
			warn(`filter err: {stateRes.Value}`)
			return state
		end
		return stateRes.Value
	end
	return state
end
-- Class
return function(props: Properties): React.ReactNode
	local baseCharacter = React.useContext(CharacterContext)
	local powerLimit = React.useContext(SessionPowerLimitContext)
	local hasMultiHair = table.find(React.useContext(SessionEntitlementsContext), MULTI_HAIR_KEY) ~= nil
	local entitlements = React.useMemo(function(): Entitlements
		return CharacterEditorConstructor.newEntitlements(powerLimit, hasMultiHair)
	end, { powerLimit :: any, hasMultiHair })

	local state: EditorState, setState: (EditorState) -> () = React.useState(function(): EditorState
		return CharacterEditorConstructor.new(baseCharacter, entitlements)
	end)
	-- the newest state, two presses can land before the render that follows the first
	local stateRef = React.useRef(state)
	local refusal: Refusal?, setRefusal: (Refusal?) -> () = React.useState(nil :: Refusal?)
	local propsRef = React.useRef(props)
	propsRef.current = props

	local setEditorState = React.useCallback(function(editedState: EditorState)
		if editedState == stateRef.current then
			return
		end
		stateRef.current = editedState
		setState(editedState)
		setRefusal(nil)
	end, {})
	local setPath = React.useCallback(function(path: string?)
		setEditorState(CharacterEditorUtil.setPath(stateRef.current, path or ""))
	end, {})
	local setIsHeroFocus = React.useCallback(function(isHeroFocus: boolean)
		setEditorState(CharacterEditorUtil.setIdentityKey(stateRef.current, if isHeroFocus then "Main" else "Secret"))
	end, {})
	local fieldCallback = React.useCallback(function(field: FieldDefinition, edit: FieldEdit)
		local stateRes = CharacterEditorUtil.write(stateRef.current, field, edit)
		if stateRes.IsOk then
			setEditorState(stateRes.Value)
			return
		end
		-- only the header of the powers has a place to show that a field was turned down
		if field.Type ~= "ChoiceList" then
			warn(`edit err: {stateRes.Value}`)
		end
		setRefusal(table.freeze({
			Field = field,
			Message = stateRes.Value,
		}))
	end, {})
	local filterText = React.useCallback(function(field: FieldDefinition)
		if field.Type ~= "Text" then
			return
		end
		local currentState = stateRef.current
		local value = CharacterEditorUtil.read(currentState, field)
		if value.Type ~= "Text" or value.Text == "" then
			return
		end
		propsRef.current.OnFilterText(table.freeze({
			Path = currentState.Path,
			IdentityKey = field.Binding.IdentityKey or currentState.IdentityKey,
			Key = field.Binding.Key,
			Text = value.Text,
		}))
	end, {})

	-- what the player owns can change while the editor is open
	React.useEffect(function()
		setEditorState(CharacterEditorUtil.setEntitlements(stateRef.current, entitlements))
		return function() end
	end, { entitlements })
	local filteredText = props.FilteredText
	React.useEffect(function()
		if filteredText then
			setEditorState(applyFilteredText(stateRef.current, filteredText))
		end
		return function() end
	end, { filteredText })
	-- whoever dealt the draft anew hands it in here. what was tried on was tried on somebody else
	local draft = props.Draft
	React.useEffect(function()
		if draft then
			setEditorState(StateUtil.setCharacter(CharacterEditorUtil.setPath(stateRef.current, ""), draft))
		end
		return function() end
	end, { draft })

	return e(CharacterContext.Provider, {
		value = state.Character,
	}, {
		PreviewCharacter = e(PreviewCharacterContext.Provider, {
			value = CharacterEditorUtil.getPreviewCharacter(state),
		}, {
			State = e(CharacterEditorStateContext.Provider, {
				value = state,
			}, {
				Path = e(PathContext.Provider, {
					value = state.Path,
				}, {
					SetPath = e(SetPathContext.Provider, {
						value = setPath,
					}, {
						IsHeroFocus = e(IsHeroFocusContext.Provider, {
							value = state.IdentityKey == "Main",
						}, {
							SetIsHeroFocus = e(SetIsHeroFocusContext.Provider, {
								value = setIsHeroFocus,
							}, {
								FieldCallback = e(CharacterEditorFieldCallback.Provider, {
									value = fieldCallback,
								}, {
									Refusal = e(CharacterEditorRefusalContext.Provider, {
										value = refusal,
									}, {
										TextFilterCallback = e(CharacterEditorTextFilterCallback.Provider, {
											value = filterText,
										}, props.children),
									}),
								}),
							}),
						}),
					}),
				}),
			}),
		}),
	})
end
