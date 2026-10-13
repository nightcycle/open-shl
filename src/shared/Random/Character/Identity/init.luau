--!strict
-- Services
-- Packages
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local IdentityConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local RandomAppearance = require("@self/Appearance")
local RandomMisc = require("@game/ReplicatedStorage/Shared/Random/Misc")
local RandomUtil = require("@game/ReplicatedStorage/Shared/Util/Random")
-- Types
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.Alignment = function(seed: number?): PseudoEnum.Alignment
	return RandomMisc.literal(seed, PseudoEnum.getEnumItems("Alignment")) :: PseudoEnum.Alignment
end

Module.Identity = function(seed: number?): IdentityType.Identity
	local rng = Random.new(seed)
	return FreezeUtil.delta(IdentityConstructor.new(), function(t)
		t.Profile.Alignment = Module.Alignment(RandomUtil.newSeed(rng))
		t.Appearance = RandomAppearance.Appearance(RandomUtil.newSeed(rng))
		return t
	end)
end

return Module
