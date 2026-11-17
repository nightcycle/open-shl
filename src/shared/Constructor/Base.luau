--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local ThemeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Theme")
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
export type BaseLayout = BaseType.BaseLayout
export type BaseInventory = BaseType.BaseInventory
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.new = function(): BaseLayout
	local out: BaseLayout = {
		ThemeId = ThemeDefinition.DEFAULT_ID,
		Furniture = {},
	}
	TableUtil.deepFreeze(out)
	return out
end

-- the default theme is free, so everybody starts out owning it
Module.newInventory = function(): BaseInventory
	local out: BaseInventory = {
		FurnitureIds = {},
		ThemeIds = { ThemeDefinition.DEFAULT_ID },
	}
	TableUtil.deepFreeze(out)
	return out
end

return Module
