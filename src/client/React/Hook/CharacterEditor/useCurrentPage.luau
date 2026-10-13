--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Contexts
local CharacterEditorPathContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/Path")
-- Hooks
local usePage = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/CharacterEditor/usePage")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
export type PageDefinition = CharacterEditorType.PageDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(): (PageDefinition?, string)
	local path = React.useContext(CharacterEditorPathContext)
	return usePage(path), path
end
