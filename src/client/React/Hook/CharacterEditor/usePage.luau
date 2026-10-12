--!strict
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
-- Contexts
-- Types
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
export type PageDefinition = CharacterEditorType.PageDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(path: string): PageDefinition?
	return React.useMemo(function(): PageDefinition?
		local pageOpt = CharacterEditorDefinition.getPage(path)
		if pageOpt.IsSome then
			return pageOpt.Value
		else
			return nil
		end
	end, { path })
end
