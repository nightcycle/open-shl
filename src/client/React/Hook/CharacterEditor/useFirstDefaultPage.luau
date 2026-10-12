--!strict
-- Services
-- Packages
-- Modules
-- Contexts
-- Hooks
local useFirstDefaultPath =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/useFirstDefaultPath")
local usePage = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/usePage")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
export type PageDefinition = CharacterEditorType.PageDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(): PageDefinition?
	return usePage(useFirstDefaultPath())
end
