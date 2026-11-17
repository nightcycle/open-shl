--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
export type FieldDefinition = CharacterEditorType.FieldDefinition
export type TextFilterCallback = (field: FieldDefinition) -> ()
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext(nil :: TextFilterCallback?)
