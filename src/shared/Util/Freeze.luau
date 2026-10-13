--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

function Util.delta<V>(t: V, fn: (V) -> V?): V
	assert(type(t) == "table", `expected table, received "{type(t)}"`)
	local newT = TableUtil.deepCopy(t)
	local finalT = fn(newT)
	if finalT == nil then
		return t
	end
	TableUtil.deepFreeze(finalT :: any)
	return finalT
end

return Util
