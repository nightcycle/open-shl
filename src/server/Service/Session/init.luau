--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
local Option = TypeUnionLib.Option
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local DataService = require("@game/ServerScriptService/Server/Service/Data")
local FightingUtil = require("@game/ServerScriptService/Server/Util/Fighting")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local LegacyImportService = require("@game/ServerScriptService/Server/Service/LegacyImport")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SpawnDefinition = require("@game/ServerScriptService/Server/Definition/Spawn")
local StoreDefinition = require("@game/ServerScriptService/Server/Definition/Store")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local QuestType = require("@game/ReplicatedStorage/Shared/Type/Quest")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
local SessionSectionType = require("@game/ServerScriptService/Server/Type/SessionSection")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Option<V> = TypeUnionLib.Option<V>
type Character = CharacterType.Character
type IdentityKey = CharacterType.IdentityKey
type EntitlementKey = EconomyType.EntitlementKey
type QuestState = QuestType.QuestState
type PlayerSave = SaveType.PlayerSave
type SavePatch = LegacyImportService.SavePatch
type SessionSection = SessionSectionType.SessionSection
type Sessions = SessionSectionType.Sessions
type Snapshot = SessionType.Snapshot
-- everything the server holds for a player. the save is what's kept between visits, the rest starts over with each
export type Session = {
	Save: PlayerSave,
	ActiveIdentityKey: IdentityKey,
	IsInMenu: boolean,
	PassEntitlements: { EntitlementKey }, -- the game passes the player owns, asked for with every visit
	Quest: QuestState?, -- only while a quest is running
}
type SessionServiceImpl = {
	__index: SessionServiceImpl,
	Get: (self: SessionService, player: Player) -> Option<Session>,
	GetActiveCharacter: (self: SessionService, player: Player) -> Option<Character>,
	GetIfInMenu: (self: SessionService, player: Player) -> boolean,
	GetEntitlements: (self: SessionService, player: Player) -> { EntitlementKey },
	Update: (
		self: SessionService,
		player: Player,
		fn: (save: PlayerSave) -> PlayerSave?
	) -> Result<PlayerSave, string>,
	SetActiveIdentity: (self: SessionService, player: Player, identityKey: IdentityKey) -> Result<true, string>,
	SetQuest: (self: SessionService, player: Player, quest: QuestState?) -> Result<true, string>,
	SetPassEntitlements: (
		self: SessionService,
		player: Player,
		entitlements: { EntitlementKey }
	) -> Result<true, string>,
}
export type SessionService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		Added: Signal.Signal<Player>,
		Removing: Signal.Signal<Player>,
		-- any write to a session, with the session as it is now + as it was before
		Changed: Signal.Signal<Player, Session, Session>,
		ActiveCharacterChanged: Signal.Signal<Player>,
		InMenuChanged: Signal.Signal<Player, boolean>,
		_Sessions: { [Player]: Session },
		_IsLoading: { [Player]: true? },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: SessionServiceImpl
))
-- Constants
-- how long a client that asked for its session before the server got to its player is kept waiting for it
local SESSION_TIMEOUT = 10
local KICK_MESSAGE = `Your save couldn't be loaded, so nothing of it was changed. Please rejoin in a moment.`
local isQuest = Type.optional(QuestType.QuestState)
local isEntitlements = Type.array(EconomyType.EntitlementKey)
-- who a character is worn as until its player turns into somebody else
local START_IDENTITY_KEY: IdentityKey = SpawnDefinition.START_IDENTITY_KEY
-- what only one game keeps of a player is only its to bring over: which fields of a patch are its own + how they get
-- into a save, what of them a client is handed + which requests are taken for them. the section of another game is
-- never required
local SECTION: SessionSection = GameDefinition.pick({
	shl1 = function(): SessionSection
		return require("@self/SHL1")
	end,
	shl2 = function(): SessionSection
		return require("@self/SHL2")
	end,
	shl3 = function(): SessionSection
		return require("@self/SHL3")
	end,
})
assert(SessionSectionType.SessionSection(SECTION))
-- Variables
-- References
-- Private Functions
local function getCharacter(save: PlayerSave, characterId: string): Character?
	for _, character in save.Characters do
		if character.Id == characterId then
			return character
		end
	end
	return nil
end

-- a save is copied as a whole with every update, so what didn't change in it can only be told by looking inside
local function getIfEqual(value: unknown, other: unknown): boolean
	if value == other then
		return true
	end
	if type(value) ~= "table" or type(other) ~= "table" then
		return false
	end
	for k, v in value :: { [unknown]: unknown } do
		if not getIfEqual(v, (other :: { [unknown]: unknown })[k]) then
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

local function getIfActiveCharacterChanged(session: Session, priorSession: Session): boolean
	local characterId = session.Save.ActiveCharacterId
	return characterId ~= priorSession.Save.ActiveCharacterId
		or session.ActiveIdentityKey ~= priorSession.ActiveIdentityKey
		or not getIfEqual(getCharacter(session.Save, characterId), getCharacter(priorSession.Save, characterId))
end

local function newSnapshot(session: Session): Snapshot
	local save = session.Save
	local out: Snapshot = {
		Characters = save.Characters,
		ActiveCharacterId = save.ActiveCharacterId,
		ActiveIdentityKey = session.ActiveIdentityKey,
		Quest = session.Quest,
	}
	if SECTION.Snapshot then
		SECTION.Snapshot(out, save)
	end
	return out
end

-- every scalar of the save a client reads, nothing else writes these attributes. the ones only one game keeps are
-- its section's to write
local function setAttributes(player: Player, save: PlayerSave, entitlements: { EntitlementKey })
	AttributeDefinition.set(player, AttributeDefinition.ActiveCharacterId, save.ActiveCharacterId)
	for _, currency: PseudoEnum.Currency in PseudoEnum.getEnumItems("Currency") do
		AttributeDefinition.set(player, AttributeDefinition.fromCurrency(currency), save.Balances[currency])
	end
	AttributeDefinition.setEntitlements(player, entitlements)
	AttributeDefinition.set(player, AttributeDefinition.PowerLimit, ProductDefinition.getPowerLimit(entitlements))
	if SECTION.SetAttributes then
		SECTION.SetAttributes(player, save)
	end
end

-- the tables a client was handed with its snapshot follow the save from here, whoever changed it
local function replicate(player: Player, save: PlayerSave, priorSave: PlayerSave)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	for _, character in save.Characters do
		if not getIfEqual(character, getCharacter(priorSave, character.Id)) then
			NetworkService:Fire(RemoteDefinition.CharacterChanged, player, character)
		end
	end
	if SECTION.Replicate then
		SECTION.Replicate(player, save, priorSave)
	end
end

-- every piece of a session is frozen by the time it gets here, so a new session is a clone with pieces swapped out
local function set(self: SessionService, player: Player, session: Session)
	local priorSession = self._Sessions[player]
	table.freeze(session)
	self._Sessions[player] = session
	if session.Save ~= priorSession.Save or session.PassEntitlements ~= priorSession.PassEntitlements then
		setAttributes(player, session.Save, self:GetEntitlements(player))
	end
	if session.Save ~= priorSession.Save then
		replicate(player, session.Save, priorSession.Save)
	end
	self.Changed:Fire(player, session, priorSession)
	if getIfActiveCharacterChanged(session, priorSession) then
		self.ActiveCharacterChanged:Fire(player)
	end
end

-- what the patch holds is written into the save by the section of the game, the way that game has it. it's only ever
-- done once for a version of the importer, the old stores aren't written to so they'd hand out the same thing again
local function import(save: PlayerSave, patch: SavePatch, importVersion: number): PlayerSave
	return FreezeUtil.delta(save, function(t: PlayerSave): PlayerSave
		SECTION.Import(t, patch)
		-- the slot the player wore last may not have made it over
		if not getCharacter(t, t.ActiveCharacterId) and t.Characters[1] then
			t.ActiveCharacterId = t.Characters[1].Id
		end
		-- written whatever the pass brought over or left behind: it ran, the same one isn't due again
		t.LegacyImportVersion = importVersion
		return t
	end)
end

-- yields. the save that comes out is locked to this server + the data service holds it as it is. whoever cancels
-- the load releases the save themselves
local function load(userId: number, getIfCanceled: () -> boolean): Result<PlayerSave, string>
	if not DataService.IsInitialized then
		return Result.err(`the data service isn't initialized`)
	end
	local saveRes = DataService:Load(StoreDefinition.Player, userId)
	if saveRes.IsErr then
		return saveRes
	end
	-- a save that had the pass of the importer there is by now is through with it. a game that takes over from nothing
	-- has no importer + nobody to ask, its saves are left at 0: the day it's given one every one of them is still due
	if LegacyImportService.IsInitialized and not LegacyImportService:GetIfDue(saveRes.Value.LegacyImportVersion) then
		return saveRes
	end
	local patchRes: Result<SavePatch, string> = Result.err(`the legacy import service isn't initialized`)
	local importVersion = 0
	if LegacyImportService.IsInitialized then
		importVersion = LegacyImportService.Version
		patchRes = LegacyImportService:Import(userId)
	end
	if getIfCanceled() or not DataService.IsInitialized then
		return Result.err(`the load was canceled`)
	end
	local problem: string
	if patchRes.IsOk then
		-- an importer only hands over what its own game keeps, a patch that holds anything else isn't written
		local isPatch, patchMsg = SECTION.Patch(patchRes.Value)
		if isPatch then
			local save = import(saveRes.Value, patchRes.Value, importVersion)
			local importRes = DataService:Save(StoreDefinition.Player, userId, save)
			if importRes.IsOk then
				return Result.ok(save)
			end
			problem = importRes.Value
		else
			problem = `the patch isn't one of {GameDefinition.ID}: {patchMsg}`
		end
	else
		problem = patchRes.Value
	end
	-- played on without it, the player would be handed their old save on top of whatever they did in the meantime. that
	-- goes for an old save that couldn't be asked for + for one the store of the new one turns down
	DataService:Release(StoreDefinition.Player, userId)
	return Result.err(`legacy import err: {problem}`)
end

-- yields. a player whose save can't be read doesn't get to play, a blank one would be written over what they have
local function add(self: SessionService, player: Player)
	-- held on to, the service lets go of them the moment it's destroyed
	local sessions, isLoading = self._Sessions, self._IsLoading
	if sessions[player] or isLoading[player] then
		return
	end
	isLoading[player] = true
	-- whoever leaves in the meantime is released on their way out
	local function getIfCanceled(): boolean
		return not self.IsInitialized or not isLoading[player]
	end
	-- a load that threw is a load that failed, the player is kicked for it like for any other
	local isDone, saveRes = pcall(load, player.UserId, getIfCanceled)
	if getIfCanceled() then
		return
	end
	if not isDone then
		saveRes = Result.err(`the load threw: {saveRes}`)
	end
	isLoading[player] = nil
	if saveRes.IsErr then
		warn(`{player.Name} was kicked: {saveRes.Value}`)
		player:Kick(KICK_MESSAGE)
		return
	end
	local session: Session = {
		Save = saveRes.Value,
		ActiveIdentityKey = START_IDENTITY_KEY,
		-- a client comes up in its menus + says so, but its avatar is in the world before that word is, + the word
		-- can get here before the session does. where a menu shelters, whoever joins starts out in one: a hit that
		-- lands first would be a fight that keeps them out of the menu they were put in
		IsInMenu = CombatDefinition.IS_MENU_SAFE,
		PassEntitlements = table.freeze({}),
	}
	table.freeze(session)
	sessions[player] = session
	setAttributes(player, session.Save, self:GetEntitlements(player))
	self.Added:Fire(player)
end

-- yields. every change is with the data service by the time it's made, what's left to do is the last write
local function remove(self: SessionService, player: Player)
	self._IsLoading[player] = nil
	if self._Sessions[player] then
		self.Removing:Fire(player)
		self._Sessions[player] = nil
	end
	if not DataService.IsInitialized then
		return
	end
	local releaseRes = DataService:Release(StoreDefinition.Player, player.UserId)
	if releaseRes.IsErr then
		warn(`the save of {player.Name} wasn't released: {releaseRes.Value}`)
	end
end
-- Class
local SessionService = {} :: SessionServiceImpl
SessionService.__index = SessionService

-- the session is frozen, a write goes through Update or one of the setters
function SessionService:Get(player: Player): Option<Session>
	return Option.from(self._Sessions[player])
end

function SessionService:GetActiveCharacter(player: Player): Option<Character>
	local session = self._Sessions[player]
	return Option.from(if session then getCharacter(session.Save, session.Save.ActiveCharacterId) else nil)
end

function SessionService:GetIfInMenu(player: Player): boolean
	local session = self._Sessions[player]
	return session ~= nil and session.IsInMenu
end

-- what the save holds + the game passes on top of it
function SessionService:GetEntitlements(player: Player): { EntitlementKey }
	local session = self._Sessions[player]
	if not session then
		return table.freeze({})
	end
	local out = table.clone(session.Save.Entitlements)
	for _, key in session.PassEntitlements do
		if not table.find(out, key) then
			table.insert(out, key)
		end
	end
	table.freeze(out)
	return out
end

-- the one way a save changes. fn gets a copy it can write to + hands it back, or nothing to leave the save as it
-- is. it can't yield. a save that doesn't pass its validator is turned down, the session stays as it was
function SessionService:Update(player: Player, fn: (save: PlayerSave) -> PlayerSave?): Result<PlayerSave, string>
	assert(DataService.IsInitialized, `the data service isn't initialized`)
	local session = self._Sessions[player]
	if not session then
		return Result.err(`{player.Name} has no session`)
	end
	local save = FreezeUtil.delta(session.Save, fn)
	if save == session.Save then
		return Result.ok(save)
	end
	-- a fn that yielded let another write in, what it made of the save from before would undo that one
	if not self.IsInitialized or self._Sessions[player] ~= session then
		return Result.err(`the save of {player.Name} changed while it was updated`)
	end
	-- the check is the data service's: it only takes what the store of the save lets in
	local saveRes = DataService:Save(StoreDefinition.Player, player.UserId, save)
	if saveRes.IsErr then
		return saveRes
	end
	local out = table.clone(session)
	out.Save = save
	-- an identity is one of the character that's worn, another character starts out as the one the game has a
	-- character come in as
	if save.ActiveCharacterId ~= session.Save.ActiveCharacterId then
		out.ActiveIdentityKey = START_IDENTITY_KEY
	end
	set(self, player, out)
	return Result.ok(save)
end

function SessionService:SetActiveIdentity(player: Player, identityKey: IdentityKey): Result<true, string>
	local session = self._Sessions[player]
	local character = session and getCharacter(session.Save, session.Save.ActiveCharacterId)
	if not session or not character then
		return Result.err(`{player.Name} has no active character`)
	end
	if not character.Identities[identityKey] then
		return Result.err(`the character has no "{identityKey}" identity`)
	end
	if session.ActiveIdentityKey ~= identityKey then
		local out = table.clone(session)
		out.ActiveIdentityKey = identityKey
		set(self, player, out)
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function SessionService:SetQuest(player: Player, quest: QuestState?): Result<true, string>
	local session = self._Sessions[player]
	if not session then
		return Result.err(`{player.Name} has no session`)
	end
	local success, msg = isQuest(quest)
	if not success then
		return Result.err(`bad quest: {msg}`)
	end
	if quest then
		TableUtil.deepFreeze(quest)
	end
	local out = table.clone(session)
	out.Quest = quest
	set(self, player, out)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function SessionService:SetPassEntitlements(player: Player, entitlements: { EntitlementKey }): Result<true, string>
	local session = self._Sessions[player]
	if not session then
		return Result.err(`{player.Name} has no session`)
	end
	local success, msg = isEntitlements(entitlements)
	if not success then
		return Result.err(`bad entitlements: {msg}`)
	end
	local out = table.clone(session)
	out.PassEntitlements = table.freeze(table.clone(entitlements))
	set(self, player, out)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

return ServiceLocker(function(): SessionService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(DataService.IsInitialized, `the data service isn't initialized`)
	assert(LegacyImportService.IsInitialized, `the legacy import service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		Added = Signal.new() :: Signal.Signal<Player>,
		Removing = Signal.new() :: Signal.Signal<Player>,
		Changed = Signal.new() :: Signal.Signal<Player, Session, Session>,
		ActiveCharacterChanged = Signal.new() :: Signal.Signal<Player>,
		InMenuChanged = Signal.new() :: Signal.Signal<Player, boolean>,
		_Sessions = {},
		_IsLoading = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, SessionService)

	NetworkService:Handle(RemoteDefinition.GetSession, function(player: Player): Result<Snapshot, string>
		-- a client can ask before the server got to its player, it's kept waiting rather than turned down. a save that's
		-- on its way is waited out however long it takes, it ends in a session or a kick
		local startTime = os.clock()
		while
			self.IsInitialized
			and not self._Sessions[player]
			and player.Parent ~= nil
			and (self._IsLoading[player] or os.clock() - startTime < SESSION_TIMEOUT)
		do
			task.wait()
		end
		local session = if self.IsInitialized then self._Sessions[player] else nil
		if not session then
			return Result.err(`{player.Name} has no session`)
		end
		return Result.ok(newSnapshot(session))
	end)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.SetInMenu, function(player: Player, isInMenu: boolean)
			local session = self._Sessions[player]
			if not session or session.IsInMenu == isInMenu then
				return
			end
			-- a client's word doesn't get an avatar out of a fight: whoever just lost health stays where they can
			-- lose more of it, + hears why
			local refusal = FightingUtil.getMenuRefusal(player.Character, isInMenu, CombatDefinition.getTime())
			if refusal then
				NetworkService:Fire(RemoteDefinition.MenuRefused, player, refusal)
				return
			end
			local out = table.clone(session)
			out.IsInMenu = isInMenu
			set(self, player, out)
			self.InMenuChanged:Fire(player, isInMenu)
		end)
	)
	-- the game's own part writes to a save through this, it's never handed the service
	if SECTION.Start then
		local sessions: Sessions = table.freeze({
			Update = function(player: Player, fn: (save: PlayerSave) -> PlayerSave?): Result<PlayerSave, string>
				return self:Update(player, fn)
			end,
		})
		local stop = SECTION.Start(sessions)
		if stop then
			table.insert(self._CleanUpCallbacks, stop)
		end
	end

	table.insert(
		self._Connections,
		Players.PlayerAdded:Connect(function(player: Player)
			add(self, player)
		end)
	)
	table.insert(
		self._Connections,
		Players.PlayerRemoving:Connect(function(player: Player)
			remove(self, player)
		end)
	)
	-- the modules the server requires yield, a player can be in before any service is
	for _, player in Players:GetPlayers() do
		task.spawn(add, self, player)
	end

	table.insert(self._CleanUpCallbacks, function()
		self.Added:Destroy()
		self.Removing:Destroy()
		self.Changed:Destroy()
		self.ActiveCharacterChanged:Destroy()
		self.InMenuChanged:Destroy()
	end)

	return self
end, function(self: SessionService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
