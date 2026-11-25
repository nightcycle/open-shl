--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Option = TypeUnionLib.Option
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local ProfileType = require("@game/ReplicatedStorage/Shared/Type/Profile")
local QuestType = require("@game/ReplicatedStorage/Shared/Type/Quest")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Option<V> = TypeUnionLib.Option<V>
type Signal<T...> = Signal.Signal<T...>
type Result<V, E> = TypeUnionLib.Result<V, E>
type Snapshot = SessionType.Snapshot
export type Character = CharacterType.Character
export type IdentityKey = CharacterType.IdentityKey
export type BaseInventory = BaseType.BaseInventory
export type Owned = EconomyType.Owned
export type QuestState = QuestType.QuestState
export type PublicProfile = ProfileType.PublicProfile
export type DailyReward = SessionType.DailyReward
export type MenuRefusal = CombatType.MenuRefusal
type SessionServiceImpl = {
	__index: SessionServiceImpl,
	GetIsLoaded: (self: SessionService) -> boolean,
	GetCharacters: (self: SessionService) -> { Character },
	GetCharacter: (self: SessionService, id: string) -> Option<Character>,
	GetActiveCharacterId: (self: SessionService) -> string,
	GetActiveIdentityKey: (self: SessionService) -> IdentityKey,
	GetActiveCharacter: (self: SessionService) -> Option<Character>,
	GetInventory: (self: SessionService) -> BaseInventory,
	GetOwned: (self: SessionService) -> Owned,
	GetQuest: (self: SessionService) -> QuestState?,
	GetProfiles: (self: SessionService) -> { PublicProfile },
	GetDailyReward: (self: SessionService) -> DailyReward?,
	SelectCharacter: (self: SessionService, id: string) -> Result<true, string>,
	SwapIdentity: (self: SessionService) -> Result<IdentityKey, string>,
	SaveCharacter: (self: SessionService, character: Character) -> Result<Character, string>,
	RollCharacter: (self: SessionService, id: string) -> Result<Character, string>,
	PurchaseItem: (self: SessionService, id: string) -> Result<true, string>,
	FilterText: (self: SessionService, text: string) -> Result<string, string>,
	SetInMenu: (self: SessionService, isInMenu: boolean) -> (),
}
export type SessionService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		Loaded: Signal<>, -- the snapshot arrived
		CharactersChanged: Signal<{ Character }>,
		ActiveCharacterChanged: Signal<string, IdentityKey>, -- the slot or the identity changed
		InventoryChanged: Signal<BaseInventory>,
		OwnedChanged: Signal<Owned>,
		QuestChanged: Signal<QuestState?>,
		ProfilesChanged: Signal<{ PublicProfile }>,
		DailyRewardGranted: Signal<DailyReward>,
		MenuRefused: Signal<MenuRefusal>, -- the server didn't count the avatar as in a menu when it was told so
		_IsLoaded: boolean,
		_Characters: { Character },
		_ActiveCharacterId: string,
		_ActiveIdentityKey: IdentityKey,
		_Inventory: BaseInventory,
		_Owned: Owned,
		_Quest: QuestState?,
		_Profiles: { PublicProfile },
		_DailyReward: DailyReward?,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: SessionServiceImpl
))
-- Constants
local SNAPSHOT_ATTEMPTS = 5
local SNAPSHOT_RETRY_DELAY = 2
-- who a character that was just picked is worn as: the identity the server has an avatar of the game come in as. its
-- word for it is on the avatar, but an avatar that already was that one doesn't say so again
local START_IDENTITY_KEY: IdentityKey = GameDefinition.tune("Main", {
	-- it comes in as the civilian, the hero is only ever turned into
	shl1 = "Secret",
}) :: any
-- the checker doesn't follow a name through the tune, so it's held to one here
assert(CharacterType.IdentityKey(START_IDENTITY_KEY))
-- Variables
-- References
-- Private Functions
local function setCharacters(self: SessionService, characters: { Character })
	self._Characters = characters
	self.CharactersChanged:Fire(characters)
end

local function setCharacter(self: SessionService, character: Character)
	local characters = table.clone(self._Characters)
	local index = #characters + 1
	for i, other in characters do
		if other.Id == character.Id then
			index = i
			break
		end
	end
	characters[index] = character
	table.freeze(characters)
	setCharacters(self, characters)
end

local function setActive(self: SessionService, id: string, identityKey: IdentityKey)
	if self._ActiveCharacterId == id and self._ActiveIdentityKey == identityKey then
		return
	end
	self._ActiveCharacterId = id
	self._ActiveIdentityKey = identityKey
	self.ActiveCharacterChanged:Fire(id, identityKey)
end

local function setInventory(self: SessionService, inventory: BaseInventory)
	self._Inventory = inventory
	self.InventoryChanged:Fire(inventory)
end

local function setOwned(self: SessionService, owned: Owned)
	self._Owned = owned
	self.OwnedChanged:Fire(owned)
end

local function setQuest(self: SessionService, quest: QuestState?)
	self._Quest = quest
	self.QuestChanged:Fire(quest)
end

local function setProfiles(self: SessionService, profiles: { PublicProfile })
	self._Profiles = profiles
	self.ProfilesChanged:Fire(profiles)
end

local function setSnapshot(self: SessionService, snapshot: Snapshot)
	-- set first, so whoever hears one of the changes below already reads the session as loaded
	self._IsLoaded = true
	setCharacters(self, snapshot.Characters)
	setActive(self, snapshot.ActiveCharacterId, snapshot.ActiveIdentityKey)
	-- a game without furniture hands none over, nothing is owned there for good
	if snapshot.Inventory then
		setInventory(self, snapshot.Inventory)
	end
	-- a game that holds nothing back has nothing to say of it
	if snapshot.Owned then
		setOwned(self, snapshot.Owned)
	end
	setQuest(self, snapshot.Quest)
	self.Loaded:Fire()
end
-- Class
local SessionService = {} :: SessionServiceImpl
SessionService.__index = SessionService

function SessionService:GetIsLoaded(): boolean
	return self._IsLoaded
end

function SessionService:GetCharacters(): { Character }
	return self._Characters
end

function SessionService:GetCharacter(id: string): Option<Character>
	for _, character in self._Characters do
		if character.Id == id then
			return Option.some(character)
		end
	end
	return Option.none()
end

-- "" until the server picked one
function SessionService:GetActiveCharacterId(): string
	return self._ActiveCharacterId
end

function SessionService:GetActiveIdentityKey(): IdentityKey
	return self._ActiveIdentityKey
end

function SessionService:GetActiveCharacter(): Option<Character>
	return self:GetCharacter(self._ActiveCharacterId)
end

function SessionService:GetInventory(): BaseInventory
	return self._Inventory
end

-- what the player has of what the game holds back at a price, nothing in a game that sells none of it
function SessionService:GetOwned(): Owned
	return self._Owned
end

function SessionService:GetQuest(): QuestState?
	return self._Quest
end

function SessionService:GetProfiles(): { PublicProfile }
	return self._Profiles
end

function SessionService:GetDailyReward(): DailyReward?
	return self._DailyReward
end

function SessionService:SelectCharacter(id: string): Result<true, string>
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local res = NetworkService:Invoke(RemoteDefinition.SelectCharacter, id)
	if res.IsOk and self.IsInitialized then
		-- a selected character is always worn as the identity one starts out in
		setActive(self, id, START_IDENTITY_KEY)
	end
	return res
end

-- the active identity only follows once the attribute of the avatar says so, the server may still call the swap off
function SessionService:SwapIdentity(): Result<IdentityKey, string>
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	return NetworkService:Invoke(RemoteDefinition.SwapIdentity, nil)
end

-- answers with the character as the server stored it, text filtered
function SessionService:SaveCharacter(character: Character): Result<Character, string>
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local res = NetworkService:Invoke(RemoteDefinition.SaveCharacter, character)
	if res.IsOk and self.IsInitialized then
		setCharacter(self, res.Value)
	end
	return res
end

-- answers with a character dealt anew for the slot. it's a draft: nothing of the session changes by it
function SessionService:RollCharacter(id: string): Result<Character, string>
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	return NetworkService:Invoke(RemoteDefinition.RollCharacter, id)
end

-- asks to buy what an item or a power is sold as. what's owned follows by the server's own word
function SessionService:PurchaseItem(id: string): Result<true, string>
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	return NetworkService:Invoke(RemoteDefinition.PurchaseItem, id)
end

function SessionService:FilterText(text: string): Result<string, string>
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	return NetworkService:Invoke(RemoteDefinition.FilterText, text)
end

function SessionService:SetInMenu(isInMenu: boolean)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	NetworkService:Fire(RemoteDefinition.SetInMenu, isInMenu)
end

return ServiceLocker(function(): SessionService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local player = Players.LocalPlayer

	local self = setmetatable({
		IsInitialized = true :: true,
		Loaded = Signal.new(),
		CharactersChanged = Signal.new(),
		ActiveCharacterChanged = Signal.new(),
		InventoryChanged = Signal.new(),
		OwnedChanged = Signal.new(),
		QuestChanged = Signal.new(),
		ProfilesChanged = Signal.new(),
		DailyRewardGranted = Signal.new(),
		MenuRefused = Signal.new(),
		_IsLoaded = false,
		_Characters = table.freeze({}),
		_ActiveCharacterId = AttributeDefinition.get(player, AttributeDefinition.ActiveCharacterId),
		_ActiveIdentityKey = AttributeDefinition.get(player.Character, AttributeDefinition.IdentityKey),
		-- nothing is owned until the server says so
		_Inventory = table.freeze({ FurnitureIds = table.freeze({}), ThemeIds = table.freeze({}) }),
		_Owned = table.freeze({ ItemIds = table.freeze({}), PowerIds = table.freeze({}) }),
		_Quest = nil :: QuestState?,
		_Profiles = table.freeze({}),
		_DailyReward = nil :: DailyReward?,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, SessionService)

	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.CharacterChanged, function(character: Character)
			setCharacter(self, character)
		end)
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.InventoryChanged, function(inventory: BaseInventory)
			setInventory(self, inventory)
		end)
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.OwnedChanged, function(owned: Owned)
			setOwned(self, owned)
		end)
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.QuestChanged, function(quest: QuestState)
			setQuest(self, quest)
		end)
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.ProfilesChanged, function(profiles: { PublicProfile })
			setProfiles(self, profiles)
		end)
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.DailyRewardGranted, function(dailyReward: DailyReward)
			-- kept, the popup that announces it may not be up yet
			self._DailyReward = dailyReward
			self.DailyRewardGranted:Fire(dailyReward)
		end)
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.MenuRefused, function(refusal: MenuRefusal)
			self.MenuRefused:Fire(refusal)
		end)
	)

	-- the server writes who the avatar is, the attributes say so before any answer does
	table.insert(
		self._Connections,
		player:GetAttributeChangedSignal(AttributeDefinition.ActiveCharacterId.Name):Connect(function()
			local id = AttributeDefinition.get(player, AttributeDefinition.ActiveCharacterId)
			if id ~= "" then
				setActive(self, id, self._ActiveIdentityKey)
			end
		end)
	)
	local identityConnection: RBXScriptConnection?
	local function onCharacter(character: Model)
		if identityConnection then
			identityConnection:Disconnect()
		end
		local function update()
			-- a new avatar has no identity until the server dressed it
			if character:GetAttribute(AttributeDefinition.IdentityKey.Name) == nil then
				return
			end
			setActive(
				self,
				self._ActiveCharacterId,
				AttributeDefinition.get(character, AttributeDefinition.IdentityKey)
			)
		end
		identityConnection = character:GetAttributeChangedSignal(AttributeDefinition.IdentityKey.Name):Connect(update)
		update()
	end
	table.insert(self._Connections, player.CharacterAdded:Connect(onCharacter))
	if player.Character then
		onCharacter(player.Character)
	end
	table.insert(self._CleanUpCallbacks, function()
		if identityConnection then
			identityConnection:Disconnect()
		end
	end)

	task.spawn(function()
		for attempt = 1, SNAPSHOT_ATTEMPTS do
			if not self.IsInitialized or not NetworkService.IsInitialized then
				return
			end
			local res = NetworkService:Invoke(RemoteDefinition.GetSession, nil)
			if not self.IsInitialized then
				return
			end
			if res.IsOk then
				setSnapshot(self, res.Value)
				return
			end
			warn(`session request {attempt} failed: {res.Value}`)
			if attempt < SNAPSHOT_ATTEMPTS then
				task.wait(SNAPSHOT_RETRY_DELAY)
			end
		end
		warn(`gave up on the session, the menus stay empty`)
	end)
	-- the roster only comes by itself when it changes, what it is right now is asked for
	task.spawn(function()
		if not NetworkService.IsInitialized then
			return
		end
		local profilesRes = NetworkService:Invoke(RemoteDefinition.GetProfiles, nil)
		if not self.IsInitialized then
			return
		end
		if profilesRes.IsOk then
			setProfiles(self, profilesRes.Value)
		else
			warn(`profiles request failed: {profilesRes.Value}`)
		end
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
	self.Loaded:Destroy()
	self.CharactersChanged:Destroy()
	self.ActiveCharacterChanged:Destroy()
	self.InventoryChanged:Destroy()
	self.OwnedChanged:Destroy()
	self.QuestChanged:Destroy()
	self.ProfilesChanged:Destroy()
	self.DailyRewardGranted:Destroy()
	self.MenuRefused:Destroy()
	table.clear(self :: any)
end)
