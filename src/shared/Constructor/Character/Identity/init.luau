--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local AppearanceConstructor = require("@self/Appearance")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
export type Identity = IdentityType.Identity
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.new = function(): Identity
	local out = {
		Profile = {
			Name = "",
			Backstory = "",
			Alignment = PseudoEnum.Alignment.TrueNeutral,
		},
		PowerSkins = {},
		Appearance = AppearanceConstructor.new(),
	}
	TableUtil.deepFreeze(out)
	return out
end

return Module
