--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
-- Components
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
-- Hooks
local useCurrentPage =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/useCurrentPage")
-- Contexts
local CharacterAppearanceContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Appearance")
local CharacterEditorFieldCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldCallback")
local PreviewCharacterAppearanceContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/PreviewAppearance")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
export type ItemDefinition = AppearanceType.ItemDefinition
export type HiddenTag = AppearanceType.HiddenTag
export type FieldDefinition = CharacterEditorType.FieldDefinition
export type PageDefinition = CharacterEditorType.PageDefinition
export type ActionInfo =
	{
		Type: "FieldUpdated",
		Path: string,
		Page: PageDefinition,
		Field: FieldDefinition,
		Value: any,
	}
	| {
		Type: "Exit",
		IsSaving: boolean,
	}
export type Properties = Frame.Properties & {
	OnAction: (ActionInfo) -> (),
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
return function(props: { children: { [string]: React.ReactNode }? }): React.ReactNode
	local page, path = useCurrentPage()
	local baseAppearance = React.useContext(CharacterAppearanceContext)
	local appearance = React.useMemo(function(): AppearanceType.Appearance
		local app = TableUtil.deepCopy(baseAppearance)

		return app
	end, { baseAppearance :: any })
	local previewAppearance = React.useMemo(function(): AppearanceType.Appearance
		local app = TableUtil.deepCopy(baseAppearance)

		return app
	end, { baseAppearance :: any })
	return e(CharacterAppearanceContext.Provider, {
		value = appearance,
	}, {
		PreviewAppearance = e(PreviewCharacterAppearanceContext.Provider, {
			value = previewAppearance,
		}, {
			CharacterEditorFieldCallback = e(CharacterEditorFieldCallback.Provider, {
				value = function(...)
					print(path, "editor", ...)
				end,
			}, props.children),
		}),
	})
end
