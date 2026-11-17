--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local CharacterEditorUtil = require("@game/ReplicatedStorage/Shared/Util/CharacterEditor")
-- Contexts
local CharacterEditorFieldDefinition =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/FieldDefinition")
local CharacterEditorStateContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/State")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
export type FieldValue = CharacterEditorType.FieldValue
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(): FieldValue?
	local state = React.useContext(CharacterEditorStateContext)
	local fieldDefinition = React.useContext(CharacterEditorFieldDefinition)
	return React.useMemo(function(): FieldValue?
		if not state or not fieldDefinition then
			return nil
		end
		return CharacterEditorUtil.read(state, fieldDefinition)
	end, { state :: any, fieldDefinition })
end
