--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
export type FieldDefinition = CharacterEditorType.FieldDefinition
export type Refusal = {
	Field: FieldDefinition, -- the field that asked for the edit
	Message: string, -- a line the player can read
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the last edit that was turned down, it's gone again once an edit goes through
return React.createContext(nil :: Refusal?)
