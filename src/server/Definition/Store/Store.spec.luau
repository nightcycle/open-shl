--!strict
-- Services
-- Packages
local SimpleTest = require("@game/ReplicatedStorage/Packages/SimpleTest")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
local Parameter = SimpleTest.Parameter
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
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
-- where a game keeps its saves + the version it's at
type PlayerStore = {
	Name: string,
	KeyFormat: string,
	Version: number,
	-- takes a save of today back to the way each earlier version of the game kept it, [1] to the first
	Earlier: { (document: { [string]: any }) -> () },
	-- takes a save of today back to one that was through the import when a save only said whether it had been, nil
	-- for a game whose saves kept the version of it from the start
	ToImported: ((document: { [string]: any }) -> ())?,
	-- where a save holds what only this game keeps, nil for a game that keeps nothing of its own in a section
	SectionKey: string?,
	-- where the saves of the other games hold theirs
	OtherSectionKeys: { string },
	-- what a save of this game keeps beside what every game does without a section around it, + what the saves of
	-- the other games keep that way
	OwnKeys: { string },
	OtherKeys: { string },
}
-- Constants
local MATERIALS = table.freeze({ Enum.Material.Plastic, Enum.Material.Neon, Enum.Material.Wood })
local POSITION_LIMIT = Vector3.new(1000, 1000, 1000)
local ROUND_TRIP_ITERATIONS = 64
-- the name + the key of the store every save of a game sits in, a server that asks under another one finds nothing
-- superhero life 2 was the only game there was when these went in, they stay where its saves have them
local SHL2_KEYS =
	table.freeze({ "Inventory", "BaseLayout", "IsApartmentLocked", "IsTutorialEnabled", "LastDailyRewardAt" })
local PLAYER_STORE: PlayerStore = GameDefinition.pick({
	-- it's still at its first version, a save of today is one
	shl1 = function(): PlayerStore
		return {
			Name = "PlayerSave",
			KeyFormat = "Player_%d",
			Version = SaveType.SHL1_VERSION,
			Earlier = {},
			SectionKey = "SHL1",
			OtherSectionKeys = { "SHL3" },
			OwnKeys = {},
			OtherKeys = SHL2_KEYS,
		}
	end,
	shl2 = function(): PlayerStore
		-- said whether it had been through the import, not which pass of it
		local function toThird(document: { [string]: any })
			document.Version = 3
			document.IsLegacyImported = document.LegacyImportVersion >= 1
			document.LegacyImportVersion = nil
		end
		-- didn't say which game wrote it
		local function toSecond(document: { [string]: any })
			toThird(document)
			document.Version = 2
			document.Game = nil
		end
		-- listed the artifacts its player owned
		local function toFirst(document: { [string]: any })
			toSecond(document)
			document.Version = 1
			document.ArtifactIds = { "costume_artifacts_a-bright-presence" }
		end
		return {
			Name = "PlayerSave",
			KeyFormat = "Player_%d",
			Version = SaveType.SHL2_VERSION,
			Earlier = { toFirst, toSecond, toThird },
			ToImported = function(document: { [string]: any })
				toSecond(document)
				document.IsLegacyImported = true
			end,
			OtherSectionKeys = { "SHL1", "SHL3" },
			OwnKeys = SHL2_KEYS,
			OtherKeys = {},
		}
	end,
	-- it's still at its first version, a save of today is one
	shl3 = function(): PlayerStore
		return {
			Name = "PlayerSave",
			KeyFormat = "Player_%d",
			Version = SaveType.SHL3_VERSION,
			Earlier = {},
			SectionKey = "SHL3",
			OtherSectionKeys = { "SHL1" },
			OwnKeys = {},
			OtherKeys = SHL2_KEYS,
		}
	end,
})
local PLAYER_STORE_NAME = PLAYER_STORE.Name
local PLAYER_KEY_FORMAT = PLAYER_STORE.KeyFormat
-- a game this server isn't
local OTHER_GAME_ID = GameDefinition.tune("shl2", { shl2 = "shl3" })
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
-- how many steps the migrations of the store that names its game were asked for
local StampedMigrationCount = 0
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
-- a document that named its game from version 2 on: version 1 was written before there was a second game
local STAMPED = StoreDefinition.new("StoreSpecStamped", getKey, 3, isLoose, function(): { [string]: any }
	return { Version = 3, Game = GameDefinition.ID }
end, {
	function(document: { [string]: any }): { [string]: any }
		StampedMigrationCount += 1
		document.Game = GameDefinition.ID
		return document
	end,
	function(document: { [string]: any }): { [string]: any }
		StampedMigrationCount += 1
		return document
	end,
}, 2) :: Store<{ [string]: any }>

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
		local stampVersions: { [string]: number } = { ["before its first version"] = 0, ["past its own version"] = 4 }
		for name, stampVersion in stampVersions do
			assert(
				not pcall(
					StoreDefinition.new,
					"StoreSpecStampless",
					getKey,
					3,
					isNote,
					newNote,
					NOTE.Migrations,
					stampVersion
				),
				`a store was made that names its game from {name}`
			)
		end
	end),

	-- every game keeps its saves under one name, so a document says which game wrote it. the document of another game
	-- isn't caught up, read or stored
	Stamp = SpecUtil.newScenario(function()
		local theirs: { [string]: { [string]: any } } = {
			["a document of another game"] = { Version = 3, Game = OTHER_GAME_ID },
			["a document of another game that's behind"] = { Version = 1, Game = OTHER_GAME_ID },
			["a document of another game that's ahead"] = { Version = 4, Game = OTHER_GAME_ID },
		}
		for name, data in theirs do
			local res = StoreDefinition.decode(STAMPED, data)
			assert(res.IsErr, `{name} was decoded`)
			assert(
				string.find(res.Value, OTHER_GAME_ID, 1, true),
				`{name} was turned down without naming it: {res.Value}`
			)
		end
		local nameless: { [string]: { [string]: any } } = {
			["a document that names no game"] = { Version = 3 },
			["a document that names no game at the version they were first named"] = { Version = 2 },
			["a document that names no game + is ahead"] = { Version = 4 },
		}
		for name, data in nameless do
			assert(StoreDefinition.decode(STAMPED, data).IsErr, `{name} was decoded`)
		end
		assert(StampedMigrationCount == 0, `a document of another game was caught up`)

		-- from before a document named its game: it's this game's all the same, catching it up is what names it
		local firstRes = StoreDefinition.decode(STAMPED, { Version = 1 })
		assert(firstRes.IsOk, `a document from before they named their game wasn't decoded: {tostring(firstRes.Value)}`)
		assert(firstRes.Value.Game == GameDefinition.ID and StampedMigrationCount == 2, `it wasn't caught up`)
		assert(
			StoreDefinition.decode(STAMPED, { Version = 3, Game = GameDefinition.ID }).IsOk,
			`its own was turned down`
		)

		assert(
			StoreDefinition.encode(STAMPED, { Version = 3, Game = OTHER_GAME_ID }).IsErr,
			`another game's was encoded`
		)
		assert(StoreDefinition.encode(STAMPED, { Version = 3 }).IsErr, `a document that names no game was encoded`)
		assert(StoreDefinition.encode(STAMPED, STAMPED.Default()).IsOk, `its own wasn't encoded`)

		-- a store that never names its game takes the field for any other
		assert(
			StoreDefinition.decode(LOOSE, { Version = 1, Game = OTHER_GAME_ID }).IsOk,
			`a field was taken for a game`
		)
		assert(
			StoreDefinition.encode(LOOSE, { Version = 1, Game = OTHER_GAME_ID }).IsOk,
			`a field was taken for a game`
		)

		-- the saves themselves
		local store = StoreDefinition.Player
		assert(store.StampVersion ~= nil, `a save doesn't name its game`)
		local dataRes = StoreDefinition.encode(store, store.Default())
		assert(dataRes.IsOk, `a new save wasn't encoded: {tostring(dataRes.Value)}`)
		local own = dataRes.Value :: { [string]: any }
		assert(own.Game == GameDefinition.ID, `a new save names "{own.Game}"`)
		local other = TableUtil.deepCopy(own)
		other.Game = OTHER_GAME_ID
		local otherRes = StoreDefinition.decode(store, other)
		assert(otherRes.IsErr, `the save of another game was decoded`)
		assert(string.find(otherRes.Value, OTHER_GAME_ID, 1, true), `it wasn't said whose it is: {otherRes.Value}`)
		local unnamed = TableUtil.deepCopy(own)
		unnamed.Game = nil
		assert(StoreDefinition.decode(store, unnamed).IsErr, `a save of today that names no game was decoded`)
	end),

	-- a data store belongs to a universe, a place that runs in another one than it was built for has no saves there
	Universe = SpecUtil.newScenario(function()
		local homes: { [string]: { number } } = {
			["a place that was built for no universe"] = { 0, 123 },
			["a place that isn't published"] = { 123, 0 },
			["a place that's neither"] = { 0, 0 },
			["a place in its own universe"] = { 123, 123 },
		}
		for name, ids in homes do
			assert(StoreDefinition.getUniverseProblem(ids[1], ids[2]) == nil, `{name} was kept from its saves`)
		end
		local problem = StoreDefinition.getUniverseProblem(123, 456)
		assert(problem ~= nil, `a place in the universe of another game was let at the saves there`)
		assert(
			string.find(problem, "123", 1, true) and string.find(problem, "456", 1, true),
			`the two universes aren't named: {problem}`
		)
	end),

	-- what only one game keeps of a player sits in a section of its save. a save holds the section of its own game,
	-- whole, + the section of no other: what one game adds never widens the save of the next
	Section = SpecUtil.newScenario(function()
		local store = StoreDefinition.Player
		local dataRes = StoreDefinition.encode(store, store.Default())
		assert(dataRes.IsOk, `a new save wasn't encoded: {tostring(dataRes.Value)}`)
		local data = dataRes.Value :: { [string]: any }
		local sectionKey = PLAYER_STORE.SectionKey
		if sectionKey then
			assert(type(data[sectionKey]) == "table", `a new save has no "{sectionKey}" section`)
			local without = TableUtil.deepCopy(data)
			without[sectionKey] = nil
			assert(StoreDefinition.decode(store, without).IsErr, `a save without its section was decoded`)
			local widened = TableUtil.deepCopy(data)
			widened[sectionKey].Rank = 1
			assert(StoreDefinition.decode(store, widened).IsErr, `a section with a field it doesn't have was decoded`)
			for key in data[sectionKey] do
				local short = TableUtil.deepCopy(data)
				short[sectionKey][key] = nil
				assert(StoreDefinition.decode(store, short).IsErr, `a section without its "{key}" was decoded`)
			end
		end
		for _, otherKey in PLAYER_STORE.OtherSectionKeys do
			assert(data[otherKey] == nil, `a new save holds the "{otherKey}" section of another game`)
			local theirs = TableUtil.deepCopy(data)
			theirs[otherKey] = {}
			assert(StoreDefinition.decode(store, theirs).IsErr, `a save with the "{otherKey}" section was decoded`)
		end
		-- the same goes for what a game keeps without a section around it
		for _, ownKey in PLAYER_STORE.OwnKeys do
			local short = TableUtil.deepCopy(data)
			short[ownKey] = nil
			assert(StoreDefinition.decode(store, short).IsErr, `a save without its "{ownKey}" was decoded`)
		end
		for _, otherKey in PLAYER_STORE.OtherKeys do
			assert(data[otherKey] == nil, `a new save holds the "{otherKey}" of another game`)
			local theirs = TableUtil.deepCopy(data)
			theirs[otherKey] = 0
			assert(
				StoreDefinition.decode(store, theirs).IsErr,
				`a save with the "{otherKey}" of another game was decoded`
			)
		end
	end),

	Player = SpecUtil.newScenario(function()
		local store = StoreDefinition.Player
		assert(store.Name == PLAYER_STORE_NAME, `the saves moved to the "{store.Name}" store`)
		assert(store.GetKey(42) == string.format(PLAYER_KEY_FORMAT, 42), `the saves moved to "{store.GetKey(42)}"`)
		assert(store.Version == PLAYER_STORE.Version, `the store is at version {store.Version}`)

		local save = store.Default()
		local dataRes = StoreDefinition.encode(store, save)
		assert(dataRes.IsOk, `a new save wasn't encoded: {tostring(dataRes.Value)}`)
		assert(getIfJson(dataRes.Value), `a new save was encoded to more than a data store takes`)
		local saveRes = StoreDefinition.decode(store, dataRes.Value)
		assert(saveRes.IsOk, `a new save wasn't decoded: {tostring(saveRes.Value)}`)
		assert(SpecUtil.getIfEqual(saveRes.Value, save), `a new save didn't come back the way it went in`)
		-- a starter suit comes with an id that's baked in, a slot that kept it would share it with everybody
		assert(store.Default().Characters[1].Id ~= save.Characters[1].Id, `two new saves share the id of a slot`)

		-- what every earlier version of the game wrote: the same save, the way it was kept then
		assert(
			#PLAYER_STORE.Earlier == store.Version - 1,
			`{#PLAYER_STORE.Earlier} of the earlier versions are held to this`
		)
		for version, toEarlier in PLAYER_STORE.Earlier do
			local earlier = TableUtil.deepCopy(dataRes.Value :: { [string]: any })
			toEarlier(earlier)
			assert(earlier.Version == version, `the save of version {version} is at version {earlier.Version}`)
			local earlierRes = StoreDefinition.decode(store, earlier)
			assert(earlierRes.IsOk, `a version {version} save wasn't decoded: {tostring(earlierRes.Value)}`)
			assert(earlierRes.Value.Version == PLAYER_STORE.Version, `a version {version} save wasn't caught up`)
			assert(SpecUtil.getIfEqual(earlierRes.Value, save), `a version {version} save changed on the way`)
		end

		-- a save keeps the version of the import it had, a new one had none. one from before that was kept only said
		-- whether it had been through it: the importer there was by then is the first
		assert(save.LegacyImportVersion == 0, `a new save starts out as imported`)
		if PLAYER_STORE.ToImported then
			local imported = TableUtil.deepCopy(dataRes.Value :: { [string]: any })
			PLAYER_STORE.ToImported(imported)
			local importedRes = StoreDefinition.decode(store, imported)
			assert(importedRes.IsOk, `a save that was imported wasn't decoded: {tostring(importedRes.Value)}`)
			assert(importedRes.Value.LegacyImportVersion == 1, `a save that was imported is due the same import again`)
			local expected = TableUtil.deepCopy(save)
			expected.LegacyImportVersion = 1
			assert(SpecUtil.getIfEqual(importedRes.Value, expected), `a save that was imported changed on the way`)
		end

		local ahead = TableUtil.deepCopy(dataRes.Value :: { [string]: any })
		ahead.Version = PLAYER_STORE.Version + 1
		local aheadRes = StoreDefinition.decode(store, ahead)
		assert(aheadRes.IsErr, `a save ahead of the server was decoded`)
		assert(string.find(aheadRes.Value, "ahead", 1, true), `it wasn't said to be ahead: {aheadRes.Value}`)
	end),
}
