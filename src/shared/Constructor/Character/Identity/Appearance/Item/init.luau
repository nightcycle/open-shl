--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
export type Item = AppearanceType.Item
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}
Module.new = function(definitionId: string): Item
	local out: Item = {
		DefinitionId = definitionId,
		TextureGroups = {},
	}
	TableUtil.deepFreeze(out)
	return out
end

return Module
