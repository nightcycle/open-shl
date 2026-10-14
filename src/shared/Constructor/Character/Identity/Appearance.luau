--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
export type Appearance = AppearanceType.Appearance
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.fix = function(appearance: Appearance): Appearance
	return FreezeUtil.delta(appearance, function(appearance: Appearance)
		return appearance
	end)
end

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
