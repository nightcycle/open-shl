--!strict
-- Services
-- Packages
-- Modules
local Frame = require("@game/ReplicatedStorage/Generated/React/Component/Frame")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
export type FieldProperties = Frame.Properties & {
	IsSelected: boolean?,
	Text: string,
	Style: CharacterEditorType.ButtonStyle,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return {}
