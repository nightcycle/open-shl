--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type Result<V, E> = TypeUnionLib.Result<V, E>
type PlayerSave = SaveType.PlayerSave
export type Validator = (value: unknown) -> (boolean, string?)
-- takes a document of the version it's listed under to the version after it
export type Migration = (document: { [string]: any }) -> { [string]: any }
-- what a handle on a document is made from. a game spells out the one it keeps its players in
export type Spec<V> = {
	Name: string,
	GetKey: (userId: number) -> string,
	Version: number,
	Validator: Validator,
	Default: () -> V,
	Migrations: { Migration }, -- one per version that came before, in order
}
-- _Signature is never set, it only carries the type of what a key holds.
-- one document per user that a single server holds at a time, it carries its Version so an older one can be caught up
export type Store<V> = {
	Name: string,
	IsReadOnly: false,
	GetKey: (userId: number) -> string,
	Version: number,
	Validator: Validator,
	Default: () -> V, -- what a user who was never saved starts out with
	Migrations: { Migration },
	_Signature: (V) -> (),
}
-- values this game only reads, they're never locked, versioned or written
export type ReadOnlyStore<V> = {
	Name: string,
	IsReadOnly: true,
	GetKey: (userId: number) -> string,
	Validator: Validator,
	_Signature: (V) -> (),
}
-- Constants
-- a data store only holds what json can spell, a datatype goes in as a table tagged with what it was
local DATATYPE_KEY = "_Datatype"
local isColor3Value = Type.strictArray(Type.number, Type.number, Type.number)
local isCFrameValue = Type.strictArray(table.unpack(table.create(12, Type.number)))
local isEnumItemValue = Type.strictArray(Type.string, Type.string)
local isVersioned = Type.interface({
	Version = Type.intersection(Type.integer, Type.numberMin(1)),
})
-- where a game keeps its players, under which key + in which shape is its own: a place that's opened in the universe
-- of another game finds nothing there to read as its own. the save of another game is never required
local PLAYER: Spec<PlayerSave> = GameDefinition.pick({
	shl1 = function(): Spec<PlayerSave>
		error(`shl1 has no save yet`)
	end,
	shl2 = function(): Spec<PlayerSave>
		return require("@self/SHL2")
	end,
	shl3 = function(): Spec<PlayerSave>
		error(`shl3 has no save yet`)
	end,
})
-- Variables
local StoreNames: { string } = {}
-- References
-- Private Functions
-- two handles on one data store would each think the keys are theirs
local function register(name: string)
	assert(not table.find(StoreNames, name), `duplicate store "{name}"`)
	table.insert(StoreNames, name)
end

local function getIfFinite(number: number): boolean
	return number == number and math.abs(number) ~= math.huge
end

-- a datatype checks out with whatever numbers it's made of, the data store doesn't
local function toStoredDatatype(datatype: string, numbers: { number }): (unknown, string?)
	for _, number in numbers do
		if not getIfFinite(number) then
			return nil, `: a {datatype} with {number} in it can't be stored`
		end
	end
	return { [DATATYPE_KEY] = datatype, Value = numbers }
end

-- the message is where in the value it went wrong, so it reads on from the name of the store
local function toStored(value: unknown): (unknown, string?)
	local valueType = typeof(value)
	if valueType == "boolean" then
		return value
	elseif valueType == "number" then
		if not getIfFinite(value :: number) then
			return nil, `: {value} can't be stored`
		end
		return value
	elseif valueType == "string" then
		if utf8.len(value :: string) == nil then
			return nil, `: a text that isn't utf8 can't be stored`
		end
		return value
	elseif valueType == "Color3" then
		local color = value :: Color3
		return toStoredDatatype("Color3", { color.R, color.G, color.B })
	elseif valueType == "CFrame" then
		return toStoredDatatype("CFrame", { (value :: CFrame):GetComponents() })
	elseif valueType == "EnumItem" then
		-- reads Enum.Material.Plastic, what's kept is the name of the enum + the name of the item
		local names = string.split(tostring(value), ".")
		return { [DATATYPE_KEY] = "EnumItem", Value = { names[2], names[3] } }
	elseif valueType ~= "table" then
		return nil, `: a {valueType} can't be stored`
	end
	local out: { [any]: unknown } = {}
	local length = #(value :: { unknown })
	local count = 0
	for k, v in value :: { [any]: unknown } do
		count += 1
		-- json has lists + maps keyed by text, nothing in between
		if length > 0 then
			if type(k) ~= "number" or k % 1 ~= 0 or k < 1 or k > length then
				return nil, `: a list with the key "{k}" can't be stored`
			end
		elseif type(k) ~= "string" or k == DATATYPE_KEY or utf8.len(k) == nil then
			return nil, `: a map with the key "{k}" can't be stored`
		end
		local stored, msg = toStored(v)
		if msg then
			return nil, `.{k}{msg}`
		end
		out[k] = stored
	end
	if length > 0 and count ~= length then
		return nil, `: a list with holes can't be stored`
	end
	return out
end

local function fromStored(value: unknown): (unknown, string?)
	if type(value) ~= "table" then
		return value
	end
	local datatype = (value :: any)[DATATYPE_KEY]
	if datatype ~= nil then
		local inner = (value :: any).Value
		if datatype == "Color3" and isColor3Value(inner) then
			return Color3.new(table.unpack(inner))
		elseif datatype == "CFrame" and isCFrameValue(inner) then
			return (CFrame.new :: any)(table.unpack(inner))
		elseif datatype == "EnumItem" and isEnumItemValue(inner) then
			-- an enum throws when it's asked for an item it doesn't have
			local success, enumItem = pcall(function(): unknown
				return (Enum :: any)[inner[1]][inner[2]]
			end)
			if success and typeof(enumItem) == "EnumItem" then
				return enumItem
			end
		end
		return nil, `: a {datatype} that can't be read`
	end
	local out: { [any]: unknown } = {}
	for k, v in value :: { [any]: unknown } do
		local read, msg = fromStored(v)
		if msg then
			return nil, `.{k}{msg}`
		end
		out[k] = read
	end
	return out
end
-- Class
local Module = {}

-- the cast at the call is what types a handle, the same way it's done for a remote. migrations holds one entry per
-- version that came before the current one: [1] takes a version 1 document to version 2
Module.new = function(
	name: string,
	getKey: (userId: number) -> string,
	version: number,
	validator: Validator,
	default: () -> any,
	migrations: { Migration }
): any
	register(name)
	assert(#migrations == version - 1, `"{name}" needs a migration from every version before {version}`)
	return table.freeze({
		Name = name,
		IsReadOnly = false,
		GetKey = getKey,
		Version = version,
		Validator = validator,
		Default = default,
		Migrations = table.freeze(table.clone(migrations)),
	})
end

Module.newReadOnly = function(name: string, getKey: (userId: number) -> string, validator: Validator): any
	register(name)
	return table.freeze({
		Name = name,
		IsReadOnly = true,
		GetKey = getKey,
		Validator = validator,
	})
end

Module.Player = Module.new(
	PLAYER.Name,
	PLAYER.GetKey,
	PLAYER.Version,
	PLAYER.Validator,
	PLAYER.Default,
	PLAYER.Migrations
) :: Store<PlayerSave>

-- nothing is stored that the validator of its store turns down
Module.encode = function<V>(store: Store<V>, value: V): Result<unknown, string>
	local success, msg = store.Validator(value)
	if not success then
		return Result.err(`{msg}`)
	end
	-- a document that's behind or ahead of its store could be written, but never read again
	if type(value) ~= "table" or (value :: any).Version ~= store.Version then
		return Result.err(`a "{store.Name}" document is at version {store.Version}`)
	end
	local data, dataMsg = toStored(value)
	if dataMsg then
		return Result.err(`{store.Name}{dataMsg}`)
	end
	return Result.ok(data)
end

-- what comes out went through every migration it was behind on + through the validator, so it can be trusted the way
-- a value made here is
Module.decode = function<V>(store: Store<V>, data: unknown): Result<V, string>
	local document, msg = fromStored(data)
	if msg then
		return Result.err(`{store.Name}{msg}`)
	end
	local isDocument, documentMsg = isVersioned(document)
	if not isDocument then
		return Result.err(`{documentMsg}`)
	end
	local out = document :: { [string]: any }
	if out.Version > store.Version then
		return Result.err(`version {out.Version} is ahead of this server, it's at {store.Version}`)
	end
	for version = out.Version, store.Version - 1 do
		local isMigrated, migrated = pcall(function(): { [string]: any }
			local upgraded = store.Migrations[version](out)
			upgraded.Version = version + 1
			return upgraded
		end)
		if not isMigrated then
			return Result.err(`the migration from version {version} threw: {migrated}`)
		end
		out = migrated
	end
	local success, validMsg = store.Validator(out)
	if not success then
		return Result.err(`{validMsg}`)
	end
	TableUtil.deepFreeze(out)
	return Result.ok(out :: any)
end

return Module
