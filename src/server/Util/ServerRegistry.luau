--!strict
-- Services
local MemoryStoreService = game:GetService("MemoryStoreService")
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Option = TypeUnionLib.Option
-- Modules
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local ServerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Server")
local StoreDefinition = require("@game/ServerScriptService/Server/Definition/Store")
-- Types
local RegistryType = require("@game/ServerScriptService/Server/Type/Registry")
local ServerType = require("@game/ReplicatedStorage/Shared/Type/Server")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Option<V> = TypeUnionLib.Option<V>
type CustomServer = RegistryType.CustomServer
type PublicServer = RegistryType.PublicServer
type Listing = ServerType.Listing
type Validator = (value: unknown) -> (boolean, string?)
-- Constants
local CUSTOM_MAP_NAME = "CustomServers"
local PUBLIC_MAP_NAME = "PublicServers"
-- as many as a sorted map hands out in one read
local MAX_LIST_COUNT = 200
local MAX_KEY_LENGTH = 128
-- the head count players like best, room beyond it doesn't make a server any better to join
local OPTIMAL_FILL = 16
-- Variables
-- References
-- Private Functions
-- yields. the memory store throws for whatever it can't do, none of that gets past here
local function call(fn: () -> unknown): Result<unknown, string>
	-- it has nothing for a place that isn't published, asking would only fill the output
	if game.GameId == 0 then
		return Result.err(`the place isn't published`)
	end
	-- a memory store belongs to a universe the way a data store does. in one this place wasn't built for every
	-- record is another game's: none of them is read, where they'd send a player is no place of this game, + none
	-- of this one's is written among them
	local universeProblem = StoreDefinition.getUniverseProblem(BUILD_CONFIG.UNIVERSE_ID, game.GameId)
	if universeProblem then
		return Result.err(universeProblem)
	end
	local success, res = pcall(fn)
	if not success then
		return Result.err(tostring(res))
	end
	return Result.ok(res)
end

-- a key that can't be stored under holds nothing, whoever asks for it
local function getIfKey(key: string): boolean
	return key ~= "" and #key <= MAX_KEY_LENGTH
end

-- what doesn't read as the record it's meant to be is as good as not there
local function read(value: unknown, validator: Validator): Option<any>
	if value == nil or not validator(value) then
		return Option.none()
	end
	TableUtil.deepFreeze(value :: any)
	return Option.some(value)
end

local function done(res: Result<unknown, string>): Result<true, string>
	if res.IsErr then
		return res
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end
-- Class
local Util = {}

-- yields. every custom server that's up, in no order that means anything
function Util.listCustomServers(): Result<{ CustomServer }, string>
	local res = call(function(): unknown
		local map = MemoryStoreService:GetSortedMap(CUSTOM_MAP_NAME)
		return map:GetRangeAsync(Enum.SortDirection.Ascending, MAX_LIST_COUNT)
	end)
	if res.IsErr then
		return res
	end
	local out: { CustomServer } = {}
	for _, entry in res.Value :: { { value: unknown } } do
		local serverOpt: Option<CustomServer> = read(entry.value, RegistryType.CustomServer)
		if serverOpt.IsSome then
			table.insert(out, serverOpt.Value)
		end
	end
	table.freeze(out)
	return Result.ok(out)
end

-- yields. a server that's gone isn't an error, there's just nothing there
function Util.getCustomServer(id: string): Result<Option<CustomServer>, string>
	if not getIfKey(id) then
		return Result.ok(Option.none())
	end
	local res = call(function(): unknown
		return (MemoryStoreService:GetSortedMap(CUSTOM_MAP_NAME):GetAsync(id))
	end)
	if res.IsErr then
		return res
	end
	return Result.ok(read(res.Value, RegistryType.CustomServer))
end

-- yields. the record is gone again after the expiry, unless it's written once more before that
function Util.setCustomServer(server: CustomServer, expiry: number): Result<true, string>
	return done(call(function(): unknown
		return MemoryStoreService:GetSortedMap(CUSTOM_MAP_NAME):SetAsync(server.Id, server, expiry)
	end))
end

-- yields
function Util.removeCustomServer(id: string): Result<true, string>
	return done(call(function(): unknown
		return MemoryStoreService:GetSortedMap(CUSTOM_MAP_NAME):RemoveAsync(id)
	end))
end

-- yields. the id is the one the definition makes out of a job id
function Util.getPublicServer(id: string): Result<Option<PublicServer>, string>
	if not getIfKey(id) then
		return Result.ok(Option.none())
	end
	local res = call(function(): unknown
		return MemoryStoreService:GetHashMap(PUBLIC_MAP_NAME):GetAsync(id)
	end)
	if res.IsErr then
		return res
	end
	return Result.ok(read(res.Value, RegistryType.PublicServer))
end

-- yields
function Util.setPublicServer(server: PublicServer, expiry: number): Result<true, string>
	return done(call(function(): unknown
		local id = ServerDefinition.getId(server.JobId)
		return MemoryStoreService:GetHashMap(PUBLIC_MAP_NAME):SetAsync(id, server, expiry)
	end))
end

-- yields
function Util.removePublicServer(id: string): Result<true, string>
	return done(call(function(): unknown
		return MemoryStoreService:GetHashMap(PUBLIC_MAP_NAME):RemoveAsync(id)
	end))
end

-- the entry code stays behind, a client only learns that there is one
function Util.newListing(server: CustomServer): Listing
	local out: Listing = {
		Id = server.Id,
		Name = server.Name,
		OwnerName = server.OwnerName,
		Region = server.Region,
		IsLocked = server.Code ~= "",
		IsPVP = server.IsPVP,
		Fill = server.Fill,
		Limit = server.Limit,
	}
	table.freeze(out)
	return out
end

-- how well a server suits a player, the browser lists the highest first + nothing that isn't above 0. the region is
-- the one of the player, "" when they have none
function Util.getScore(server: CustomServer, userId: number, region: string): number
	if server.Fill == 0 or table.find(server.BannedIds, userId) then
		return -math.huge
	end
	local room = math.max(math.min(server.Limit, OPTIMAL_FILL) - server.Fill, 0)
	local score = 1 + server.Fill + room * 3
	-- company counts for far more than anything else
	score += 100 * (server.Fill - 1)
	if server.Code ~= "" then
		score *= 0.5
	end
	if server.Fill >= server.Limit then
		score *= 0.5
	end
	if region ~= "" and server.Region ~= region then
		score *= 0.1
	end
	return score
end

return Util
