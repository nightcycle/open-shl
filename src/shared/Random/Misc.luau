--!strict
-- Services
-- Packages
-- Modules
local RandomUtil = require("@game/ReplicatedStorage/Shared/Util/Random")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

function Module.literal<V>(seed: number?, choices: { V }): V
	local rng = Random.new(seed)
	assert(#choices > 0, `bad choice count`)
	return choices[rng:NextInteger(1, #choices)]
end

function Module.array<V>(seed: number?, valueFn: (number?) -> V, len: number?): { V }
	local rng = Random.new(seed)
	len = len or rng:NextInteger(0, 12)
	assert(len, `bad length`)
	local out = {}
	if len > 0 then
		for i = 1, len do
			local value = valueFn(RandomUtil.newSeed(rng))
			if value == nil then
				continue
			end
			table.insert(out, value)
		end
	end
	return out
end

function Module.set<V>(seed: number?, valueFn: (number?) -> V, targetLen: number?): { V }
	local rng = Random.new(seed)
	targetLen = targetLen or rng:NextInteger(0, 12)
	assert(targetLen, `bad targetLen`)
	local out = {}
	local hits: { [V]: true? } = {}
	if targetLen > 0 then
		for i = 1, targetLen do
			local value = valueFn(RandomUtil.newSeed(rng))
			if value == nil then
				continue
			end
			if hits[value] ~= nil then
				continue
			end
			hits[value] = true
			table.insert(out, value)
		end
	end
	return out
end

function Module.map<K, V>(seed: number?, keyFn: (number?) -> K, valueFn: (number?) -> V, targetLen: number?): { [K]: V }
	local rng = Random.new(seed)
	targetLen = targetLen or rng:NextInteger(0, 12)
	assert(targetLen, `bad targetLen`)
	local out: { [K]: V } = {}
	if targetLen > 0 then
		for i = 1, targetLen do
			local key = keyFn(RandomUtil.newSeed(rng))
			if out[key] ~= nil then
				continue
			end
			local value = valueFn(RandomUtil.newSeed(rng))
			if value == nil then
				continue
			end
			out[key] = value
		end
	end
	return out
end

return Module
