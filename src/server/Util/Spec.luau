--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
-- Types
type Test = SimpleTest.Test
-- Constants
-- the package can't run a test that has no parameter + runs every test more often than its parameters have values
local SCENARIO_ITERATIONS = 2
-- Variables
-- References
-- Private Functions
-- Class
-- what the specs share. a spec sits in the folder of what it tests the way a story does, the game never requires one:
-- the server runs them before it starts, in a build that was made with TESTS_ENABLED
local Util = {}

-- a test that walks through one story instead of a spread of inputs: fn yields as it likes + throws where it's let
-- down. it's only ever walked through once, every later run answers with whatever the first one came to
function Util.newScenario(fn: () -> ()): Test
	local isRun = false
	local problem: string? = nil
	return SimpleTest.Test.new({ SimpleTest.Parameter.Static.new("Scenario", true) }, function(): boolean
		if not isRun then
			isRun = true
			local success, msg = pcall(fn :: any)
			if not success then
				problem = tostring(msg)
			end
		end
		if problem then
			error(problem, 0)
		end
		return true
	end, SCENARIO_ITERATIONS)
end

-- whatever a table holds is compared, not which table it is. a datatype is equal the way == has it
function Util.getIfEqual(value: unknown, other: unknown): boolean
	if value == other then
		return true
	end
	if type(value) ~= "table" or type(other) ~= "table" then
		return false
	end
	for k, v in value :: { [unknown]: unknown } do
		if not Util.getIfEqual(v, (other :: { [unknown]: unknown })[k]) then
			return false
		end
	end
	for k in other :: { [unknown]: unknown } do
		if (value :: { [unknown]: unknown })[k] == nil then
			return false
		end
	end
	return true
end

return Util
