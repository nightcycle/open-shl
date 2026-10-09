--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
-- Contexts
local CharacterEditorPathContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/Path")
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
export type PageDefinition = CharacterEditorType.PageDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(): PageDefinition?
	local path = React.useContext(CharacterEditorPathContext)
	return React.useMemo(function(): PageDefinition?
		local pageOpt = CharacterEditorDefinition.getPage(path)
		if pageOpt.IsSome then
			return pageOpt.Value
		else
			return nil
		end
	end, { path })
end
