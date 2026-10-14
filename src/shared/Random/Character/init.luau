--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local RandomIdentity = require("@self/Identity")
local RandomUtil = require("@game/ReplicatedStorage/Shared/Util/Random")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.Character = function(seed: number?): CharacterType.Character
	local rng = Random.new(seed)
	local out: CharacterType.Character = {
		Id = tostring(RandomUtil.newSeed(rng)),
		Powers = {},
		Identities = {
			Main = RandomIdentity.Identity(true, RandomUtil.newSeed(rng)),
			Secret = RandomIdentity.Identity(false, RandomUtil.newSeed(rng)),
		},
	}
	TableUtil.deepFreeze(out)
	return out
end

return Module
