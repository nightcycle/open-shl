--!strict
-- Services
local HttpService = game:GetService("HttpService")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local LegacyDataMigration = require("@game/ServerScriptService/Server/Util/LegacyDataMigration")
local StoreDefinition = require("@game/ServerScriptService/Server/Definition/Store")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type ReadOnlyStore<V> = StoreDefinition.ReadOnlyStore<V>
type WornArtifact = LegacyDataMigration.WornArtifact
-- Constants
local isWornArtifact = Type.strictArray(Type.string, Type.boolean, Type.boolean, Type.boolean, Type.boolean)
-- json has null where a list had a hole, so a list that's read back can skip an index
local isList = Type.map(Type.integer, Type.any)
-- Variables
-- References
-- Private Functions
-- every store of the old game kept one value per user, under the same key
local function getKey(userId: number): string
	return `user_{userId}`
end
-- Class
local Module = {}

-- the stores of the game this one takes over from. a validator asks for no more than the script that wrote the store
-- couldn't get wrong: what a store holds never changes again, so a value that's turned down is turned down on every
-- visit. what's inside a value is checked piece by piece as it's converted, see LegacyDataMigration

-- json: every slot of the player, a slot is its id + its secret + its super identity
Module.Characters = StoreDefinition.newReadOnly("SavedCharacters", getKey, Type.string) :: ReadOnlyStore<string>

-- the id of the slot that was played last, "None" before the first one
Module.LastCharacterId = StoreDefinition.newReadOnly("LastID2", getKey, Type.string) :: ReadOnlyStore<string>

Module.Credits = StoreDefinition.newReadOnly("Credits", getKey, Type.number) :: ReadOnlyStore<number>

Module.Gems = StoreDefinition.newReadOnly("Gems", getKey, Type.number) :: ReadOnlyStore<number>

Module.WornArtifact =
	StoreDefinition.newReadOnly("LastArtifact2", getKey, isWornArtifact) :: ReadOnlyStore<WornArtifact>

-- the name of every piece of furniture + every theme that was bought
Module.Furniture =
	StoreDefinition.newReadOnly("Furniture", getKey, Type.array(Type.string)) :: ReadOnlyStore<{ string }>

-- json: the theme of the base, its title + every piece that was placed in it
Module.BaseLayout = StoreDefinition.newReadOnly("Organization", getKey, Type.string) :: ReadOnlyStore<string>

-- whether the tutorial is on. the old game stored whatever a client sent it, so it can be anything
Module.Tutorial = StoreDefinition.newReadOnly("Tutorial", getKey, Type.any) :: ReadOnlyStore<unknown>

-- when the daily reward was last handed out, in unix seconds
Module.DailyReward = StoreDefinition.newReadOnly("LastLogins987654321", getKey, Type.number) :: ReadOnlyStore<number>

-- the stores that hold json all hold a list
Module.decodeList = function(json: string): Result<{ [number]: unknown }, string>
	local success, list = pcall(function(): unknown
		return HttpService:JSONDecode(json)
	end)
	if not success then
		return Result.err(`it isn't json: {list}`)
	end
	local isValid, msg = isList(list)
	if not isValid then
		return Result.err(`it isn't a list: {msg}`)
	end
	return Result.ok(list :: { [number]: unknown })
end

return Module
