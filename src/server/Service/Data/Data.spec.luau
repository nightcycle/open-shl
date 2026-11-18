--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local DataService = require("@game/ServerScriptService/Server/Service/Data")
local FakeDataStoreUtil = require("@game/ServerScriptService/Server/Util/FakeDataStore")
local SpecUtil = require("@game/ServerScriptService/Server/Util/Spec")
local StoreDefinition = require("@game/ServerScriptService/Server/Definition/Store")
-- Types
type Store<V> = StoreDefinition.Store<V>
type ReadOnlyStore<V> = StoreDefinition.ReadOnlyStore<V>
type DataService = DataService.DataService
type FakeDataStoreService = FakeDataStoreUtil.FakeDataStoreService
-- at version 2, version 1 called its name Label
type Hero = {
	Version: number,
	Coins: number,
	Name: string,
}
-- Constants
local USER_ID = 1
local OTHER_SERVER_ID = "another-server"
-- what the data service waits between its attempts, a spec that's through much sooner didn't see them made
local RETRY_DELAY = 1
local LOCK_RETRY_DELAY = 2
-- past it a lock belongs to a server that crashed
local LOCK_TIMEOUT = 300
local MAX_ATTEMPTS = 4
local isHero = Type.strictInterface({
	Version = Type.literal(2),
	Coins = Type.integer,
	Name = Type.string,
})
-- Variables
-- References
-- Private Functions
local function newHero(coins: number, name: string): Hero
	return table.freeze({
		Version = 2,
		Coins = coins,
		Name = name,
	})
end

local function getHeroKey(userId: number): string
	return `Hero_{userId}`
end

local function getScoreKey(userId: number): string
	return `user_{userId}`
end

local function start(): () -> ()
	assert(not DataService.IsInitialized, `the data service is already initialized`)
	return DataService.init()
end

-- yields. the data service is up on a fake of its own for as long as fn runs + taken down again whatever comes of it
local function run(fn: (dataService: DataService, fake: FakeDataStoreService) -> ())
	local destroy = start()
	assert(DataService.IsInitialized, `the data service isn't initialized`)
	local fake = FakeDataStoreUtil.new()
	DataService:SetDataStoreService(fake)
	local success, msg = pcall(fn :: any, DataService, fake)
	destroy()
	if not success then
		error(msg, 0)
	end
end
-- Class
local HERO = StoreDefinition.new("DataSpecHero", getHeroKey, 2, isHero, function(): Hero
	return newHero(0, "")
end, {
	function(document: { [string]: any }): { [string]: any }
		document.Name = document.Label
		document.Label = nil
		return document
	end,
}) :: Store<Hero>
local DEFAULTLESS = StoreDefinition.new("DataSpecDefaultless", getHeroKey, 2, isHero, function(): Hero
	error(`a default that can't be made`)
end, HERO.Migrations) :: Store<Hero>
local SCORE = StoreDefinition.newReadOnly("DataSpecScore", getScoreKey, Type.number) :: ReadOnlyStore<number>
local TAGS =
	StoreDefinition.newReadOnly("DataSpecTags", getScoreKey, Type.array(Type.string)) :: ReadOnlyStore<{ string }>
local HERO_KEY = getHeroKey(USER_ID)
local SCORE_KEY = getScoreKey(USER_ID)

return {
	-- a user who was never saved gets the default + nothing of it is in the data store before the release
	LoadNew = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			local heroRes = dataService:Load(HERO, USER_ID)
			assert(heroRes.IsOk, `a new hero wasn't loaded: {tostring(heroRes.Value)}`)
			assert(SpecUtil.getIfEqual(heroRes.Value, newHero(0, "")), `a new hero isn't the default`)
			local held = fake:Peek(HERO.Name, HERO_KEY) :: any
			assert(type(held) == "table" and type(held.Lock) == "table", `a hero that's loaded isn't locked`)
			assert(held.Lock.ServerId ~= "" and held.Lock.ServerId ~= OTHER_SERVER_ID, `the lock names no server`)
			assert(held.Data == nil, `a new hero was written before anything asked for it`)

			assert(dataService:Release(HERO, USER_ID).IsOk, `a new hero wasn't released`)
			local released = fake:Peek(HERO.Name, HERO_KEY) :: any
			assert(released.Lock == nil, `a hero that was released is still locked`)
			assert(SpecUtil.getIfEqual(released.Data, newHero(0, "")), `the default wasn't stored with the release`)
		end)
	end),

	LoadStored = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			fake:Plant(HERO.Name, HERO_KEY, { Data = newHero(7, "stored") })
			local heroRes = dataService:Load(HERO, USER_ID)
			assert(heroRes.IsOk, `a stored hero wasn't loaded: {tostring(heroRes.Value)}`)
			assert(SpecUtil.getIfEqual(heroRes.Value, newHero(7, "stored")), `what was loaded isn't what was stored`)
			assert(table.isfrozen(heroRes.Value), `a hero that was loaded isn't frozen`)

			local againRes = dataService:Load(HERO, USER_ID)
			assert(againRes.IsErr, `a hero was loaded twice`)
			assert(string.find(againRes.Value, "already loaded", 1, true), `the second load err: {againRes.Value}`)
		end)
	end),

	-- handing in a value doesn't write it, the release does + the next load reads it back
	SaveThenRelease = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			fake:Plant(HERO.Name, HERO_KEY, { Data = newHero(7, "stored") })
			assert(dataService:Load(HERO, USER_ID).IsOk, `a stored hero wasn't loaded`)
			local callCount = #fake:GetCalls()
			assert(dataService:Save(HERO, USER_ID, newHero(8, "saved")).IsOk, `a hero wasn't saved`)
			assert(#fake:GetCalls() == callCount, `a save called the data store`)
			assert((fake:Peek(HERO.Name, HERO_KEY) :: any).Data.Coins == 7, `a save wrote to the data store`)

			-- a value its store turns down leaves what's pending as it was
			assert(dataService:Save(HERO, USER_ID, newHero(8.5, "broken")).IsErr, `half a coin was saved`)
			assert(
				dataService:Save(HERO, USER_ID, { Version = 1, Coins = 8, Name = "" }).IsErr,
				`a hero was saved behind`
			)

			assert(dataService:Release(HERO, USER_ID).IsOk, `a hero wasn't released`)
			local released = fake:Peek(HERO.Name, HERO_KEY) :: any
			assert(released.Lock == nil, `a hero that was released is still locked`)
			assert(SpecUtil.getIfEqual(released.Data, newHero(8, "saved")), `the release didn't store what was saved`)
			assert(dataService:Save(HERO, USER_ID, newHero(9, "late")).IsErr, `a hero was saved past its release`)

			local heroRes = dataService:Load(HERO, USER_ID)
			assert(heroRes.IsOk, `a hero wasn't loaded after its release: {tostring(heroRes.Value)}`)
			assert(SpecUtil.getIfEqual(heroRes.Value, newHero(8, "saved")), `the next load didn't read what was saved`)
		end)
	end),

	-- a save that wasn't read can't be told from one that isn't there, writing it would wipe what the player had
	Unloaded = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			assert(dataService:Save(HERO, USER_ID, newHero(1, "unread")).IsErr, `a hero that wasn't loaded was saved`)
			assert(dataService:Release(HERO, USER_ID).IsOk, `releasing a hero that wasn't loaded is an error`)
			assert(fake:Peek(HERO.Name, HERO_KEY) == nil, `a hero that wasn't loaded was written`)
			assert(#fake:GetCalls() == 0, `the data store was called for a hero that wasn't loaded`)
		end)
	end),

	-- a server that holds a save is waited for, a save it still holds after that is left with it
	LockHeld = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			local planted = {
				Lock = { ServerId = OTHER_SERVER_ID, At = os.time() },
				Data = newHero(7, "theirs"),
			}
			fake:Plant(HERO.Name, HERO_KEY, planted)
			local startTime = os.clock()
			local heroRes = dataService:Load(HERO, USER_ID)
			assert(heroRes.IsErr, `a hero another server holds was loaded`)
			assert(os.clock() - startTime > LOCK_RETRY_DELAY, `the other server wasn't waited for`)
			assert(
				SpecUtil.getIfEqual(fake:Peek(HERO.Name, HERO_KEY), planted),
				`a hero another server holds was written`
			)
			assert(dataService:Save(HERO, USER_ID, newHero(0, "blank")).IsErr, `a hero that didn't load was saved`)
		end)
	end),

	-- a player who hops between servers can arrive before the last one let go
	LockLetGo = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			fake:Plant(HERO.Name, HERO_KEY, {
				Lock = { ServerId = OTHER_SERVER_ID, At = os.time() },
				Data = newHero(7, "early"),
			})
			task.delay(LOCK_RETRY_DELAY / 2, function()
				fake:Plant(HERO.Name, HERO_KEY, { Data = newHero(9, "late") })
			end)
			local heroRes = dataService:Load(HERO, USER_ID)
			assert(heroRes.IsOk, `a hero the other server let go of wasn't loaded: {tostring(heroRes.Value)}`)
			assert(
				SpecUtil.getIfEqual(heroRes.Value, newHero(9, "late")),
				`the last write of the other server is missing`
			)
		end)
	end),

	LockDead = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			fake:Plant(HERO.Name, HERO_KEY, {
				Lock = { ServerId = OTHER_SERVER_ID, At = os.time() - LOCK_TIMEOUT - 1 },
				Data = newHero(7, "left behind"),
			})
			local heroRes = dataService:Load(HERO, USER_ID)
			assert(heroRes.IsOk, `a hero a dead server held wasn't loaded: {tostring(heroRes.Value)}`)
			assert(
				SpecUtil.getIfEqual(heroRes.Value, newHero(7, "left behind")),
				`what the dead server held is missing`
			)
			assert(
				(fake:Peek(HERO.Name, HERO_KEY) :: any).Lock.ServerId ~= OTHER_SERVER_ID,
				`the lock wasn't taken over`
			)
		end)
	end),

	-- a server whose lock was taken over is behind, what it holds isn't written over what the other one stored
	LockLost = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			assert(dataService:Load(HERO, USER_ID).IsOk, `a new hero wasn't loaded`)
			assert(dataService:Save(HERO, USER_ID, newHero(5, "ours")).IsOk, `a hero wasn't saved`)
			local planted = {
				Lock = { ServerId = OTHER_SERVER_ID, At = os.time() },
				Data = newHero(99, "theirs"),
			}
			fake:Plant(HERO.Name, HERO_KEY, planted)
			assert(dataService:Release(HERO, USER_ID).IsErr, `a hero another server took over was released`)
			assert(SpecUtil.getIfEqual(fake:Peek(HERO.Name, HERO_KEY), planted), `what the other server stored is gone`)
			assert(dataService:Save(HERO, USER_ID, newHero(6, "ours")).IsErr, `a hero another server took was saved`)
		end)
	end),

	-- a data store can fail for no reason of ours, a call is tried again before it's given up on
	Retry = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			fake:Plant(HERO.Name, HERO_KEY, { Data = newHero(7, "stored") })
			fake:FailCall(1, "Throttle")
			local startTime = os.clock()
			local heroRes = dataService:Load(HERO, USER_ID)
			assert(heroRes.IsOk, `one throttled call kept a hero from loading: {tostring(heroRes.Value)}`)
			assert(os.clock() - startTime > RETRY_DELAY / 2, `the data store wasn't given a moment`)
			local calls = fake:GetCalls()
			assert(
				#calls == 2 and calls[1].Failure == "Throttle" and calls[2].Failure == nil,
				`the call wasn't retried once`
			)
		end)
	end),

	-- a save that can't be asked for isn't a save that's blank
	RetriesSpent = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			fake:Plant(HERO.Name, HERO_KEY, { Data = newHero(7, "stored") })
			fake:FailKey(HERO.Name, HERO_KEY, "Error")
			local heroRes = dataService:Load(HERO, USER_ID)
			fake:FailKey(HERO.Name, HERO_KEY, nil)
			assert(heroRes.IsErr, `a hero was loaded from a data store that's down`)
			assert(#fake:GetCalls() == MAX_ATTEMPTS, `the data store was asked {#fake:GetCalls()} times`)
			assert(dataService:Save(HERO, USER_ID, newHero(0, "blank")).IsErr, `a hero that didn't load was saved`)
			assert(dataService:Release(HERO, USER_ID).IsOk, `releasing a hero that didn't load is an error`)
			assert(
				SpecUtil.getIfEqual(fake:Peek(HERO.Name, HERO_KEY), { Data = newHero(7, "stored") }),
				`a hero that didn't load was written`
			)
		end)
	end),

	-- what can't be read is left for whoever looks into it, a load that wrote a default over it would be the end of it
	Unreadable = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			local values: { [string]: unknown } = {
				["a text"] = "hero",
				["a document without its envelope"] = newHero(7, "bare"),
				["a lock that names no server"] = { Lock = { At = os.time() }, Data = newHero(7, "locked") },
				["a document its validator fails"] = { Data = { Version = 2, Coins = "many", Name = "rich" } },
				["a document without a version"] = { Data = { Coins = 7, Name = "old" } },
				["a document ahead of the server"] = { Data = { Version = 3, Coins = 7, Name = "new", Rank = 1 } },
				["a datatype that can't be read"] = {
					Data = { Version = 2, Coins = 7, Name = { _Datatype = "Color3", Value = {} } },
				},
			}
			for name, value in values do
				fake:Plant(HERO.Name, HERO_KEY, value)
				assert(dataService:Load(HERO, USER_ID).IsErr, `{name} was loaded`)
				assert(SpecUtil.getIfEqual(fake:Peek(HERO.Name, HERO_KEY), value), `{name} was written over`)
				assert(dataService:Save(HERO, USER_ID, newHero(0, "blank")).IsErr, `a hero was saved over {name}`)
			end
		end)
	end),

	-- a document that's behind is caught up as it loads, the data store has it caught up with the next write
	Migration = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			fake:Plant(HERO.Name, HERO_KEY, { Data = { Version = 1, Coins = 3, Label = "veteran" } })
			local heroRes = dataService:Load(HERO, USER_ID)
			assert(heroRes.IsOk, `a version 1 hero wasn't loaded: {tostring(heroRes.Value)}`)
			assert(SpecUtil.getIfEqual(heroRes.Value, newHero(3, "veteran")), `a version 1 hero wasn't caught up`)
			assert((fake:Peek(HERO.Name, HERO_KEY) :: any).Data.Version == 1, `the load wrote more than its lock`)
			assert(dataService:Release(HERO, USER_ID).IsOk, `a hero that was caught up wasn't released`)
			assert(
				SpecUtil.getIfEqual(fake:Peek(HERO.Name, HERO_KEY), { Data = newHero(3, "veteran") }),
				`a hero that was caught up wasn't stored that way`
			)
		end)
	end),

	-- whatever goes wrong once the lock is ours, it's handed back
	DefaultThrows = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			assert(dataService:Load(DEFAULTLESS, USER_ID).IsErr, `a hero was loaded without a default`)
			local held = fake:Peek(DEFAULTLESS.Name, HERO_KEY) :: any
			assert(type(held) == "table" and held.Lock == nil and held.Data == nil, `the lock wasn't handed back`)
			assert(
				dataService:Save(DEFAULTLESS, USER_ID, newHero(0, "blank")).IsErr,
				`a hero that didn't load was saved`
			)
		end)
	end),

	-- whoever leaves in the middle of their load is released on their way out
	ReleaseWhileLoading = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			fake:Plant(HERO.Name, HERO_KEY, { Data = newHero(7, "stored") })
			fake:SetLatency(0.5)
			local heroRes: unknown = nil
			task.spawn(function()
				heroRes = dataService:Load(HERO, USER_ID)
			end)
			task.wait(0.1)
			assert(heroRes == nil, `the load didn't take its time`)
			assert(dataService:Release(HERO, USER_ID).IsOk, `a hero that's loading wasn't released`)
			fake:SetLatency(0)
			while heroRes == nil do
				task.wait()
			end
			assert((heroRes :: any).IsErr, `a hero was loaded past its release`)
			assert(
				SpecUtil.getIfEqual(fake:Peek(HERO.Name, HERO_KEY), { Data = newHero(7, "stored") }),
				`the lock of a load that was called off wasn't handed back`
			)
		end)
	end),

	-- a release that fails holds on to the last changes: they aren't saved over, read around or dropped
	ReleaseFails = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			fake:Plant(HERO.Name, HERO_KEY, { Data = newHero(7, "stored") })
			assert(dataService:Load(HERO, USER_ID).IsOk, `a stored hero wasn't loaded`)
			assert(dataService:Save(HERO, USER_ID, newHero(4, "last change")).IsOk, `a hero wasn't saved`)
			fake:FailKey(HERO.Name, HERO_KEY, "Error")
			assert(dataService:Release(HERO, USER_ID).IsErr, `a hero was released into a data store that's down`)
			assert((fake:Peek(HERO.Name, HERO_KEY) :: any).Data.Coins == 7, `a write that failed got through`)
			assert(dataService:Save(HERO, USER_ID, newHero(5, "late")).IsErr, `a hero was saved past its release`)
			-- the data store is behind on them, a load would hand out less than they left with
			local heroRes = dataService:Load(HERO, USER_ID)
			assert(heroRes.IsErr, `a hero was loaded while its last changes aren't saved`)
			assert(string.find(heroRes.Value, "aren't saved", 1, true), `the load err: {heroRes.Value}`)

			fake:FailKey(HERO.Name, HERO_KEY, nil)
			assert(dataService:Release(HERO, USER_ID).IsOk, `the release wasn't made up for`)
			assert(
				SpecUtil.getIfEqual(fake:Peek(HERO.Name, HERO_KEY), { Data = newHero(4, "last change") }),
				`the last changes didn't make it`
			)
			local againRes = dataService:Load(HERO, USER_ID)
			assert(againRes.IsOk, `a hero wasn't loaded once it was saved: {tostring(againRes.Value)}`)
			assert(SpecUtil.getIfEqual(againRes.Value, newHero(4, "last change")), `the last changes weren't loaded`)
		end)
	end),

	-- the server destroys the service as it closes, everything that's loaded is written + let go of by then
	Flush = SpecUtil.newScenario(function()
		local fake: FakeDataStoreService
		run(function(dataService: DataService, prepared: FakeDataStoreService)
			fake = prepared
			fake:Plant(HERO.Name, HERO_KEY, { Data = newHero(7, "stored") })
			assert(dataService:Load(HERO, USER_ID).IsOk, `a stored hero wasn't loaded`)
			assert(dataService:Load(HERO, USER_ID + 1).IsOk, `a new hero wasn't loaded`)
			assert(dataService:Save(HERO, USER_ID, newHero(8, "closing")).IsOk, `a hero wasn't saved`)
		end)
		assert(
			SpecUtil.getIfEqual(fake:Peek(HERO.Name, HERO_KEY), { Data = newHero(8, "closing") }),
			`a hero wasn't written as the service was destroyed`
		)
		assert(
			SpecUtil.getIfEqual(fake:Peek(HERO.Name, getHeroKey(USER_ID + 1)), { Data = newHero(0, "") }),
			`a new hero wasn't written as the service was destroyed`
		)
	end),

	-- a store this game only reads is never locked or written
	Read = SpecUtil.newScenario(function()
		run(function(dataService: DataService, fake: FakeDataStoreService)
			local noneRes = dataService:Read(SCORE, USER_ID)
			assert(noneRes.IsOk and noneRes.Value.IsNone, `a key that holds nothing wasn't read as nothing`)

			fake:Plant(SCORE.Name, SCORE_KEY, 12)
			local scoreRes = dataService:Read(SCORE, USER_ID)
			assert(scoreRes.IsOk and scoreRes.Value.IsSome and scoreRes.Value.Value == 12, `a score wasn't read`)

			fake:Plant(SCORE.Name, SCORE_KEY, "twelve")
			assert(dataService:Read(SCORE, USER_ID).IsErr, `a score its validator fails was read`)

			fake:Plant(TAGS.Name, SCORE_KEY, { "a", "b" })
			fake:FailCall(1, "Error")
			local tagsRes = dataService:Read(TAGS, USER_ID)
			assert(tagsRes.IsOk and tagsRes.Value.IsSome, `one failed call kept the tags from being read`)
			assert(
				SpecUtil.getIfEqual(tagsRes.Value.Value, { "a", "b" }),
				`the tags weren't read the way they're stored`
			)
			assert(table.isfrozen(tagsRes.Value.Value :: any), `the tags that were read aren't frozen`)

			for _, call in fake:GetCalls() do
				assert(call.Method == "GetAsync", `a read only store was written to`)
			end
			assert(fake:Peek(SCORE.Name, SCORE_KEY) == "twelve", `a read changed what the key holds`)
		end)
	end),
}
