--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
export type EditorState = CharacterEditorType.EditorState
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return React.createContext(nil :: EditorState?)
