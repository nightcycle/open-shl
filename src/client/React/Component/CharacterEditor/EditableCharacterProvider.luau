--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
-- Hooks
local useCurrentPage =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/useCurrentPage")
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local CharacterEditorFieldCallback =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldCallback")
local PreviewCharacterContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Preview")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
export type Properties = {
	children: { [string]: React.ReactNode }?,
}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
return function(props: Properties): React.ReactNode
	local _, path = useCurrentPage()
	local baseCharacter = React.useContext(CharacterContext)
	local character = React.useMemo(function(): CharacterType.Character
		return TableUtil.deepCopy(baseCharacter)
	end, { baseCharacter :: any })
	local previewCharacter = React.useMemo(function(): CharacterType.Character
		return TableUtil.deepCopy(character)
	end, { character :: any })
	return e(CharacterContext.Provider, {
		value = character,
	}, {
		PreviewCharacter = e(PreviewCharacterContext.Provider, {
			value = previewCharacter,
		}, {
			CharacterEditorFieldCallback = e(CharacterEditorFieldCallback.Provider, {
				value = function(field: CharacterEditorFieldCallback.FieldDefinition, value: any?)
					print(path, "editor", field, value)
				end,
			}, props.children),
		}),
	})
end
