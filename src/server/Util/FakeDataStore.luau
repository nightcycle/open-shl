--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
-- Types
-- the slice of the data store api the data service calls, the real service fits it as well as the fake does
export type DataStore = {
	GetAsync: (self: DataStore, key: string) -> unknown,
	-- the transform gets what the key holds + answers with what to store, nil leaves the key as it is
	UpdateAsync: (self: DataStore, key: string, transform: (value: unknown) -> unknown) -> unknown,
}
export type DataStoreService = {
	GetDataStore: (self: DataStoreService, name: string) -> DataStore,
}
export type Failure = "Throttle" | "Error"
export type Call = {
	Method: "GetAsync" | "UpdateAsync",
	StoreName: string,
	Key: string,
	Failure: Failure?,
}
-- the slice + what a test scripts it with
export type FakeDataStoreService = DataStoreService & {
	-- how long every call takes, a call always yields at least a step
	SetLatency: (self: FakeDataStoreService, latency: number) -> (),
	-- the index counts from the next call, which is 1
	FailCall: (self: FakeDataStoreService, index: number, failure: Failure) -> (),
	-- every call for the key fails until it's set back to nil
	FailKey: (self: FakeDataStoreService, storeName: string, key: string, failure: Failure?) -> (),
	-- writes a value the way another server would, behind the back of whoever uses the fake
	Plant: (self: FakeDataStoreService, storeName: string, key: string, value: unknown) -> (),
	-- what a key holds, without it counting as a call
	Peek: (self: FakeDataStoreService, storeName: string, key: string) -> unknown,
	GetCalls: (self: FakeDataStoreService) -> { Call },
}
-- Constants
-- worded the way the real service words them
local FAILURE_MESSAGES: { [Failure]: string } = table.freeze({
	Throttle = "301: request dropped. Request was throttled, but throttled request queue was full.",
	Error = "502: API Services rejected request with error. HTTP 500 (Internal Server Error)",
})
-- Variables
-- References
-- Private Functions
-- nothing that's stored is ever shared with a caller, the real service hands out a fresh copy every time too
local function copy(value: unknown): unknown
	if type(value) == "table" then
		return TableUtil.deepCopy(value :: any)
	end
	return value
end

-- the real service only takes what json can spell, a value it would turn down is turned down here as well
local function getIfStorable(value: unknown): boolean
	local valueType = typeof(value)
	if valueType == "string" then
		return utf8.len(value :: string) ~= nil
	elseif valueType == "number" then
		return value == value and math.abs(value :: number) ~= math.huge
	elseif valueType ~= "table" then
		return valueType == "boolean"
	end
	local length = #(value :: { unknown })
	for k, v in value :: { [any]: unknown } do
		local isKey = if length > 0
			then type(k) == "number" and k <= length
			else type(k) == "string" and utf8.len(k) ~= nil
		if not isKey or not getIfStorable(v) then
			return false
		end
	end
	return true
end
-- Class
local Util = {}

function Util.new(): FakeDataStoreService
	local values: { [string]: { [string]: unknown } } = {}
	local dataStores: { [string]: DataStore } = {}
	local calls: { Call } = {}
	local callFailures: { [number]: Failure } = {}
	local keyFailures: { [string]: { [string]: Failure } } = {}
	local latency = 0

	local function getValues(storeName: string): { [string]: unknown }
		local storeValues = values[storeName] or {}
		values[storeName] = storeValues
		return storeValues
	end

	-- yields like the real thing + throws whatever failure the call was set up with
	local function call(method: "GetAsync" | "UpdateAsync", storeName: string, key: string)
		local storeFailures = keyFailures[storeName]
		local failure: Failure? = callFailures[#calls + 1] or (storeFailures and storeFailures[key])
		table.insert(calls, {
			Method = method,
			StoreName = storeName,
			Key = key,
			Failure = failure,
		})
		task.wait(latency)
		if failure then
			error(FAILURE_MESSAGES[failure], 0)
		end
	end

	local function newDataStore(name: string): DataStore
		local storeValues = getValues(name)
		return {
			GetAsync = function(_: DataStore, key: string): unknown
				call("GetAsync", name, key)
				return copy(storeValues[key])
			end,
			-- the transform runs once the wait is over, so it's handed whatever was written in the meantime
			UpdateAsync = function(_: DataStore, key: string, transform: (value: unknown) -> unknown): unknown
				call("UpdateAsync", name, key)
				local value = transform(copy(storeValues[key]))
				if value == nil then
					return nil
				end
				if not getIfStorable(value) then
					error(
						`104: Cannot store {typeof(value)} in data store. Data stores can only accept valid UTF-8 characters.`,
						0
					)
				end
				storeValues[key] = copy(value)
				return copy(value)
			end,
		}
	end

	return {
		GetDataStore = function(_: DataStoreService, name: string): DataStore
			local dataStore = dataStores[name] or newDataStore(name)
			dataStores[name] = dataStore
			return dataStore
		end,
		SetLatency = function(_: FakeDataStoreService, value: number)
			latency = value
		end,
		FailCall = function(_: FakeDataStoreService, index: number, failure: Failure)
			callFailures[#calls + index] = failure
		end,
		FailKey = function(_: FakeDataStoreService, storeName: string, key: string, failure: Failure?)
			local storeFailures = keyFailures[storeName] or {}
			keyFailures[storeName] = storeFailures
			storeFailures[key] = failure
		end,
		Plant = function(_: FakeDataStoreService, storeName: string, key: string, value: unknown)
			assert(value == nil or getIfStorable(value), `a data store can't hold the value`)
			getValues(storeName)[key] = copy(value)
		end,
		Peek = function(_: FakeDataStoreService, storeName: string, key: string): unknown
			return copy(getValues(storeName)[key])
		end,
		GetCalls = function(_: FakeDataStoreService): { Call }
			return table.clone(calls)
		end,
	}
end

return Util
