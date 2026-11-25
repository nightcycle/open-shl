--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
-- Modules
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local ServiceDefinition = require("@game/ServerScriptService/Server/Definition/Service")
-- Types
type Service = ServiceLocker.InitializationInterface
-- Constants
-- Variables
local Services: { Service } = {}
local DestroyCallbacks: { () -> () } = {}
-- References
local Server = IndexUtil.waitForPath("game/ServerScriptService/Server")
local Shared = IndexUtil.waitForPath("game/ReplicatedStorage/Shared")
-- Private Functions
-- yields. a spec is a module named after what it tests + ".spec", in the folder of what it tests. each sets up + takes
-- down the services it needs, which is why they run before the server has any of its own up. what both sides share
-- is held to its specs here as well
local function test()
	local tests: { [string]: SimpleTest.Test } = {}
	local passCount, failCount = 0, 0
	local modules = Server:GetDescendants()
	table.move(Shared:GetDescendants(), 1, #Shared:GetDescendants(), #modules + 1, modules)
	for _, module in modules do
		if not module:IsA("ModuleScript") or not string.match(module.Name, "%.spec$") then
			continue
		end
		local isRead, spec = pcall(require :: any, module)
		if not isRead then
			failCount += 1
			warn(`[test] {module:GetFullName()}: it threw as it was read: {spec}`)
			continue
		end
		-- a spec that has nothing to hold this game to says so with an empty list: what it tests is another game's
		if type(spec) == "table" and next(spec) == nil then
			continue
		end
		-- the package leaves out a spec it can't make sense of without a word, so each is asked for on its own
		local moduleTests = SimpleTest.search({ module })
		if next(moduleTests) == nil then
			failCount += 1
			warn(`[test] {module:GetFullName()}: no test could be read from it`)
		end
		for path, moduleTest in moduleTests do
			tests[path] = moduleTest
		end
	end
	local summary = SimpleTest.run(tests, "Overview")
	assert(summary.Type == "Overview", `the tests weren't summed up as an overview`)
	for path, result in summary.Results do
		if result == "Success" then
			passCount += 1
		else
			failCount += 1
			warn(`[test] {path}: {result}`)
		end
	end
	-- what a play-test looks for
	print(`[test] {passCount} passed, {failCount} failed`)
end
-- Class
-- only in a build that was made to be tested. a run that throws its way out of the package can't keep the server down
if BUILD_CONFIG.TESTS_ENABLED then
	local success, msg = pcall(test :: any)
	if not success then
		warn(`[test] the run threw: {msg}`)
	end
end

-- every one of this game's is in before the first starts. they start in the order of the list + stop in the reverse
for _, entry in ServiceDefinition.list() do
	table.insert(Services, entry.Load())
end
for _, service in Services do
	table.insert(DestroyCallbacks, service.init())
end
-- whatever takes a remote has taken it by now, one that's left is one this game doesn't have
assert(NetworkService.IsInitialized, `the network service isn't initialized`)
NetworkService:Seal()

game:BindToClose(function()
	for index = #DestroyCallbacks, 1, -1 do
		-- the data service writes every save as it stops, a service that throws on its way out can't be in its way
		local success, msg = pcall(DestroyCallbacks[index] :: any)
		if not success then
			warn(`destroy err: {msg}`)
		end
	end
end)

-- what a play-test looks for: every service is up
print(`[boot] server ok ({GameDefinition.ID})`)
