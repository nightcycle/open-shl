--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
local Parameter = SimpleTest.Parameter
-- Modules
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
local StoreDefinition = require("@game/ServerScriptService/Server/Definition/Store")
-- Types
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type Store<V> = StoreDefinition.Store<V>
-- one of every kind of value a save is made of
type Sample = {
	Version: number,
	Color: Color3,
	CFrame: CFrame,
	Material: Enum.Material,
	Text: string,
	Number: number,
	IsFlagged: boolean,
	List: { Color3 },
	Map: { [string]: { CFrame: CFrame } },
}
-- a document that changed shape twice: version 1 called its title Name, version 2 had no tags yet
type Note = {
	Version: number,
	Title: string,
	Tags: { string },
}
-- Constants
local MATERIALS = table.freeze({ Enum.Material.Plastic, Enum.Material.Neon, Enum.Material.Wood })
local POSITION_LIMIT = Vector3.new(1000, 1000, 1000)
local ROUND_TRIP_ITERATIONS = 64
-- the name + the key of the store every save of the game sits in, a server that asks under another one finds nothing
local PLAYER_STORE_NAME = "PlayerSave"
local PLAYER_KEY_FORMAT = "Player_%d"
local isSample = Type.strictInterface({
	Version = Type.literal(1),
	Color = Type.Color3,
	CFrame = Type.CFrame,
	Material = Type.enum(Enum.Material),
	Text = Type.string,
	Number = Type.number,
	IsFlagged = Type.boolean,
	List = Type.array(Type.Color3),
	Map = Type.map(Type.string, Type.strictInterface({ CFrame = Type.CFrame })),
})
local isNote = Type.strictInterface({
	Version = Type.literal(3),
	Title = Type.string,
	Tags = Type.array(Type.string),
})
-- lets anything in next to its version, what's turned down for it is turned down by the store
local isLoose = Type.interface({
	Version = Type.integer,
})
-- Variables
-- References
-- Private Functions
local function getKey(userId: number): string
	return `Spec_{userId}`
end

local function newNote(): Note
	return {
		Version = 3,
		Title = "",
		Tags = {},
	}
end

-- a data store takes text, numbers, booleans + tables of them, nothing else
local function getIfJson(value: unknown): boolean
	if type(value) ~= "table" then
		return type(value) == "string" or type(value) == "number" or type(value) == "boolean"
	end
	for _, v in value :: { [unknown]: unknown } do
		if not getIfJson(v) then
			return false
		end
	end
	return true
end
-- Class
local SAMPLE = StoreDefinition.new("StoreSpecSample", getKey, 1, isSample, function(): Sample
	error(`a sample has no default`)
end, {}) :: Store<Sample>
local NOTE = StoreDefinition.new("StoreSpecNote", getKey, 3, isNote, newNote, {
	function(document: { [string]: any }): { [string]: any }
		document.Title = document.Name
		document.Name = nil
		return document
	end,
	function(document: { [string]: any }): { [string]: any }
		document.Tags = {}
		return document
	end,
}) :: Store<Note>
local LOOSE = StoreDefinition.new("StoreSpecLoose", getKey, 1, isLoose, function(): { [string]: any }
	return { Version = 1 }
end, {}) :: Store<{ [string]: any }>
local BROKEN = StoreDefinition.new("StoreSpecBroken", getKey, 2, isLoose, function(): { [string]: any }
	return { Version = 2 }
end, {
	function(_document: { [string]: any }): { [string]: any }
		error(`a migration that can't be done`)
	end,
}) :: Store<{ [string]: any }>

return {
	-- whatever a save holds comes back out of the data store the way it went in
	RoundTrip = SimpleTest.Test.new(
		{
			Parameter.Color3.new("Color"),
			Parameter.Vector3.new("Position", -POSITION_LIMIT, POSITION_LIMIT),
			Parameter.Integer.new("QuarterTurns", 0, 3),
			Parameter.Choose.new("Material", MATERIALS, tostring),
			Parameter.String.new("Text", 0, 40),
			Parameter.Float.new("Number", -1e6, 1e6),
			Parameter.Boolean.new("IsFlagged"),
		},
		function(
			color: Color3,
			position: Vector3,
			quarterTurns: number,
			material: Enum.Material,
			text: string,
			number: number,
			isFlagged: boolean
		): boolean
			local cframe = CFrame.new(position) * CFrame.Angles(0, math.rad(90 * quarterTurns), 0)
			local sample: Sample = {
				Version = 1,
				Color = color,
				CFrame = cframe,
				Material = material,
				Text = text,
				Number = number,
				IsFlagged = isFlagged,
				List = { color, Color3.new() },
				Map = {
					Here = { CFrame = cframe },
					There = { CFrame = CFrame.new(position) },
				},
			}
			local dataRes = StoreDefinition.encode(SAMPLE, sample)
			assert(dataRes.IsOk, `the sample wasn't encoded: {tostring(dataRes.Value)}`)
			assert(getIfJson(dataRes.Value), `what was encoded holds more than a data store takes`)
			local sampleRes = StoreDefinition.decode(SAMPLE, dataRes.Value)
			assert(sampleRes.IsOk, `the sample wasn't decoded: {tostring(sampleRes.Value)}`)
			assert(table.isfrozen(sampleRes.Value), `what was decoded isn't frozen`)
			return SpecUtil.getIfEqual(sampleRes.Value, sample)
		end,
		ROUND_TRIP_ITERATIONS
	),

	-- a value the data store would turn down or mangle never gets as far as the data store
	EncodeRefusal = SpecUtil.newScenario(function()
		local holes: { any } = { 1, 2, 3 }
		holes[2] = nil
		local mixed: { [any]: any } = { 1, 2 }
		mixed.Key = true
		local values: { [string]: unknown } = {
			["a number that isn't one"] = 0 / 0,
			["an endless number"] = math.huge,
			["a text that isn't utf8"] = "\255\254",
			["a list with holes"] = holes,
			["a list with a named key"] = mixed,
			["a map with a number for a key"] = { [1.5] = true },
			["a map that passes for a datatype"] = { _Datatype = "Color3", Value = { 1, 1, 1 } },
			["a datatype with a number that isn't one"] = CFrame.new(0 / 0, 0, 0),
			["a datatype the store has no form for"] = Vector3.new(1, 2, 3),
			["a function"] = function() end,
			["an instance"] = Instance.new("Folder"),
		}
		for name, value in values do
			local dataRes = StoreDefinition.encode(LOOSE, { Version = 1, Field = value })
			assert(dataRes.IsErr, `{name} was encoded`)
			-- the message is where in the document it went wrong
			assert(
				string.find(dataRes.Value, `{LOOSE.Name}.Field`, 1, true),
				`{name} was turned down without saying where: {dataRes.Value}`
			)
		end
		assert(StoreDefinition.encode(SAMPLE, { Version = 1 } :: any).IsErr, `a sample its validator fails was encoded`)
		-- a document that's behind or ahead of its store could be written, but never read again
		assert(StoreDefinition.encode(LOOSE, { Version = 2 }).IsErr, `a document ahead of its store was encoded`)
		assert(StoreDefinition.encode(NOTE, newNote()).IsOk, `a note wasn't encoded`)
	end),

	-- a document goes through every migration it's behind on, in order, + through none it isn't
	VersionChain = SpecUtil.newScenario(function()
		local first = { Version = 1, Name = "first" }
		local firstRes = StoreDefinition.decode(NOTE, first)
		assert(firstRes.IsOk, `a version 1 note wasn't decoded: {tostring(firstRes.Value)}`)
		assert(
			SpecUtil.getIfEqual(firstRes.Value, { Version = 3, Title = "first", Tags = {} }),
			`a version 1 note didn't come out as a version 3 one`
		)
		assert(table.isfrozen(firstRes.Value), `a note that was decoded isn't frozen`)
		assert(
			SpecUtil.getIfEqual(first, { Version = 1, Name = "first" }),
			`the migrations wrote to the document they were handed`
		)

		local secondRes = StoreDefinition.decode(NOTE, { Version = 2, Title = "second" })
		assert(secondRes.IsOk, `a version 2 note wasn't decoded: {tostring(secondRes.Value)}`)
		assert(
			SpecUtil.getIfEqual(secondRes.Value, { Version = 3, Title = "second", Tags = {} }),
			`a version 2 note didn't come out as a version 3 one`
		)

		local third = { Version = 3, Title = "third", Tags = { "kept" } }
		local thirdRes = StoreDefinition.decode(NOTE, third)
		assert(thirdRes.IsOk, `a version 3 note wasn't decoded: {tostring(thirdRes.Value)}`)
		assert(SpecUtil.getIfEqual(thirdRes.Value, third), `a note of the current version was changed`)

		-- written by a server that's newer than this one, it's not this one's to guess at
		local aheadRes = StoreDefinition.decode(NOTE, { Version = 4, Title = "ahead", Tags = {}, Mood = "new" })
		assert(aheadRes.IsErr, `a note ahead of the server was decoded`)
		assert(string.find(aheadRes.Value, "ahead", 1, true), `it wasn't said to be ahead: {aheadRes.Value}`)

		assert(StoreDefinition.decode(NOTE, { Version = 1 }).IsErr, `a note its validator fails was decoded`)
		local brokenRes = StoreDefinition.decode(BROKEN, { Version = 1 })
		assert(brokenRes.IsErr, `a document was decoded past a migration that threw`)
		assert(StoreDefinition.decode(BROKEN, { Version = 2 }).IsOk, `a document was held up by a migration behind it`)

		local unversioned: { [string]: unknown } = {
			["a text"] = "note",
			["a document without a version"] = { Title = "none", Tags = {} },
			["a document at version 0"] = { Version = 0, Title = "zero", Tags = {} },
			["a document at half a version"] = { Version = 2.5, Title = "half", Tags = {} },
			["a document with a text for a version"] = { Version = "3", Title = "text", Tags = {} },
		}
		for name, data in unversioned do
			assert(StoreDefinition.decode(NOTE, data).IsErr, `{name} was decoded`)
		end
		assert(StoreDefinition.decode(NOTE, nil).IsErr, `nothing was decoded`)
	end),

	DecodeRefusal = SpecUtil.newScenario(function()
		local fields: { [string]: unknown } = {
			["a color that's short of a number"] = { _Datatype = "Color3", Value = { 1, 1 } },
			["a cframe that's short of a number"] = { _Datatype = "CFrame", Value = { 1, 2, 3 } },
			["an enum item that was never there"] = { _Datatype = "EnumItem", Value = { "Material", "Vibranium" } },
			["an enum that was never there"] = { _Datatype = "EnumItem", Value = { "Metal", "Plastic" } },
			["a datatype the store has no form for"] = { _Datatype = "Vector3", Value = { 1, 2, 3 } },
		}
		for name, field in fields do
			local res = StoreDefinition.decode(LOOSE, { Version = 1, Field = field })
			assert(res.IsErr, `{name} was decoded`)
			assert(
				string.find(res.Value, `{LOOSE.Name}.Field`, 1, true),
				`{name} was turned down without saying where: {res.Value}`
			)
		end
	end),

	-- a handle that's put together wrong doesn't get as far as a data store
	Handle = SpecUtil.newScenario(function()
		assert(
			not pcall(StoreDefinition.new, "StoreSpecShort", getKey, 3, isNote, newNote, {}),
			`a store was made without a migration from every version before its own`
		)
		assert(
			not pcall(StoreDefinition.new, NOTE.Name, getKey, 3, isNote, newNote, NOTE.Migrations),
			`two stores were made under one name`
		)
		assert(
			not pcall(StoreDefinition.newReadOnly, NOTE.Name, getKey, isNote),
			`a read only store was made under the name of another`
		)
		assert(table.isfrozen(NOTE) and table.isfrozen(NOTE.Migrations), `a store isn't frozen`)
	end),

	Player = SpecUtil.newScenario(function()
		local store = StoreDefinition.Player
		assert(store.Name == PLAYER_STORE_NAME, `the saves moved to the "{store.Name}" store`)
		assert(store.GetKey(42) == string.format(PLAYER_KEY_FORMAT, 42), `the saves moved to "{store.GetKey(42)}"`)
		assert(store.Version == SaveType.CURRENT_VERSION, `the store is at version {store.Version}`)

		local save = store.Default()
		local dataRes = StoreDefinition.encode(store, save)
		assert(dataRes.IsOk, `a new save wasn't encoded: {tostring(dataRes.Value)}`)
		assert(getIfJson(dataRes.Value), `a new save was encoded to more than a data store takes`)
		local saveRes = StoreDefinition.decode(store, dataRes.Value)
		assert(saveRes.IsOk, `a new save wasn't decoded: {tostring(saveRes.Value)}`)
		assert(SpecUtil.getIfEqual(saveRes.Value, save), `a new save didn't come back the way it went in`)
		-- a starter suit comes with an id that's baked in, a slot that kept it would share it with everybody
		assert(store.Default().Characters[1].Id ~= save.Characters[1].Id, `two new saves share the id of a slot`)

		-- what the first version of the game wrote: the same save + the artifacts its player owned
		local first = TableUtil.deepCopy(dataRes.Value :: { [string]: any })
		first.Version = 1
		first.ArtifactIds = { "costume_artifacts_a-bright-presence" }
		local firstRes = StoreDefinition.decode(store, first)
		assert(firstRes.IsOk, `a version 1 save wasn't decoded: {tostring(firstRes.Value)}`)
		assert(firstRes.Value.Version == SaveType.CURRENT_VERSION, `a version 1 save wasn't caught up`)
		assert(SpecUtil.getIfEqual(firstRes.Value, save), `a version 1 save lost more than its artifacts on the way`)

		local ahead = TableUtil.deepCopy(dataRes.Value :: { [string]: any })
		ahead.Version = SaveType.CURRENT_VERSION + 1
		local aheadRes = StoreDefinition.decode(store, ahead)
		assert(aheadRes.IsErr, `a save ahead of the server was decoded`)
		assert(string.find(aheadRes.Value, "ahead", 1, true), `it wasn't said to be ahead: {aheadRes.Value}`)
	end),
}
