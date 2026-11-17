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
local BaseConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Base")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
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
export type QuestState = QuestType.QuestState
export type PublicProfile = ProfileType.PublicProfile
export type DailyReward = SessionType.DailyReward
type SessionServiceImpl = {
	__index: SessionServiceImpl,
	GetIsLoaded: (self: SessionService) -> boolean,
	GetCharacters: (self: SessionService) -> { Character },
	GetCharacter: (self: SessionService, id: string) -> Option<Character>,
	GetActiveCharacterId: (self: SessionService) -> string,
	GetActiveIdentityKey: (self: SessionService) -> IdentityKey,
	GetActiveCharacter: (self: SessionService) -> Option<Character>,
	GetArtifactIds: (self: SessionService) -> { string },
	GetInventory: (self: SessionService) -> BaseInventory,
	GetQuest: (self: SessionService) -> QuestState?,
	GetProfiles: (self: SessionService) -> { PublicProfile },
	GetDailyReward: (self: SessionService) -> DailyReward?,
	SelectCharacter: (self: SessionService, id: string) -> Result<true, string>,
	SwapIdentity: (self: SessionService) -> Result<IdentityKey, string>,
	SaveCharacter: (self: SessionService, character: Character) -> Result<Character, string>,
	FilterText: (self: SessionService, text: string) -> Result<string, string>,
	SetInMenu: (self: SessionService, isInMenu: boolean) -> (),
}
export type SessionService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		Loaded: Signal<>, -- the snapshot arrived
		CharactersChanged: Signal<{ Character }>,
		ActiveCharacterChanged: Signal<string, IdentityKey>, -- the slot or the identity changed
		ArtifactIdsChanged: Signal<{ string }>,
		InventoryChanged: Signal<BaseInventory>,
		QuestChanged: Signal<QuestState?>,
		ArtifactGranted: Signal<string>, -- the definition id
		ProfilesChanged: Signal<{ PublicProfile }>,
		DailyRewardGranted: Signal<DailyReward>,
		_IsLoaded: boolean,
		_Characters: { Character },
		_ActiveCharacterId: string,
		_ActiveIdentityKey: IdentityKey,
		_ArtifactIds: { string },
		_Inventory: BaseInventory,
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

local function setArtifactIds(self: SessionService, artifactIds: { string })
	self._ArtifactIds = artifactIds
	self.ArtifactIdsChanged:Fire(artifactIds)
end

local function setInventory(self: SessionService, inventory: BaseInventory)
	self._Inventory = inventory
	self.InventoryChanged:Fire(inventory)
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
	setArtifactIds(self, snapshot.ArtifactIds)
	setInventory(self, snapshot.Inventory)
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

function SessionService:GetArtifactIds(): { string }
	return self._ArtifactIds
end

function SessionService:GetInventory(): BaseInventory
	return self._Inventory
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
		-- a selected character is always worn as its super identity
		setActive(self, id, "Main")
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
		ArtifactIdsChanged = Signal.new(),
		InventoryChanged = Signal.new(),
		QuestChanged = Signal.new(),
		ArtifactGranted = Signal.new(),
		ProfilesChanged = Signal.new(),
		DailyRewardGranted = Signal.new(),
		_IsLoaded = false,
		_Characters = table.freeze({}),
		_ActiveCharacterId = AttributeDefinition.get(player, AttributeDefinition.ActiveCharacterId),
		_ActiveIdentityKey = AttributeDefinition.get(player.Character, AttributeDefinition.IdentityKey),
		_ArtifactIds = table.freeze({}),
		_Inventory = BaseConstructor.newInventory(),
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
		NetworkService:Connect(RemoteDefinition.QuestChanged, function(quest: QuestState)
			setQuest(self, quest)
		end)
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.ArtifactGranted, function(definitionId: string)
			if table.find(self._ArtifactIds, definitionId) then
				return
			end
			local artifactIds = table.clone(self._ArtifactIds)
			table.insert(artifactIds, definitionId)
			table.freeze(artifactIds)
			setArtifactIds(self, artifactIds)
			self.ArtifactGranted:Fire(definitionId)
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
	self.ArtifactIdsChanged:Destroy()
	self.InventoryChanged:Destroy()
	self.QuestChanged:Destroy()
	self.ArtifactGranted:Destroy()
	self.ProfilesChanged:Destroy()
	self.DailyRewardGranted:Destroy()
	table.clear(self :: any)
end)
