--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
export type Appearance = AppearanceType.Appearance
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.new = function(): Appearance
	local out = {
		Items = {},
		Transitions = {},
		HiddenTags = {},
	}
	TableUtil.deepFreeze(out)
	return out
end

return Module
