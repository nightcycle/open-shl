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
local Future = TypeUnionLib.Future
-- Modules
local AppearanceConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BaseConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Base")
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local CharacterSlotUtil = require("@game/ServerScriptService/Server/Util/CharacterSlot")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local TextFilterUtil = require("@game/ServerScriptService/Server/Util/TextFilter")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
local QuestType = require("@game/ReplicatedStorage/Shared/Type/Quest")
local SessionType = require("@game/ReplicatedStorage/Shared/Type/Session")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Option<V> = TypeUnionLib.Option<V>
type Appearance = AppearanceType.Appearance
type BaseInventory = BaseType.BaseInventory
type Character = CharacterType.Character
type Power = CharacterType.Power
type IdentityKey = CharacterType.IdentityKey
type EntitlementKey = EconomyType.EntitlementKey
type Identity = IdentityType.Identity
type PowerSkin = IdentityType.PowerSkin
type QuestState = QuestType.QuestState
type Profile = {
	Name: string,
	Backstory: string,
	Alignment: PseudoEnum.Alignment,
}
-- every table the server holds for a player, the same thing a client is handed when it joins
export type Session = SessionType.Snapshot
type SessionServiceImpl = {
	__index: SessionServiceImpl,
	Get: (self: SessionService, player: Player) -> Option<Session>,
	GetActiveCharacter: (self: SessionService, player: Player) -> Option<Character>,
	GetIfInMenu: (self: SessionService, player: Player) -> boolean,
	SetCharacter: (self: SessionService, player: Player, character: Character) -> Result<Character, string>,
	SetActiveCharacter: (self: SessionService, player: Player, characterId: string) -> Result<true, string>,
	SetActiveIdentity: (self: SessionService, player: Player, identityKey: IdentityKey) -> Result<true, string>,
	SetArtifactIds: (self: SessionService, player: Player, artifactIds: { string }) -> Result<true, string>,
	SetInventory: (self: SessionService, player: Player, inventory: BaseInventory) -> Result<true, string>,
	SetQuest: (self: SessionService, player: Player, quest: QuestState?) -> Result<true, string>,
	GetBalance: (self: SessionService, player: Player, currency: PseudoEnum.Currency) -> number,
	SetBalance: (
		self: SessionService,
		player: Player,
		currency: PseudoEnum.Currency,
		balance: number
	) -> Result<true, string>,
	GetEntitlements: (self: SessionService, player: Player) -> { EntitlementKey },
	GrantEntitlement: (self: SessionService, player: Player, key: EntitlementKey) -> Result<true, string>,
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
		_IsInMenu: { [Player]: true? },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: SessionServiceImpl
))
-- Constants
local ARTIFACT_CATEGORY = "artifacts"
local HAIR_CATEGORY = "hair"
local MAX_NAME_LENGTH = CharacterEditorDefinition.MAX_NAME_LENGTH
local MAX_BACKSTORY_LENGTH = CharacterEditorDefinition.MAX_BACKSTORY_LENGTH
local FILTER_TIMEOUT = 5
-- how long a client that asked for its session before the server got to its player is kept waiting for it
local SESSION_TIMEOUT = 10
local isArtifactIds = Type.array(Type.string)
local isQuest = Type.optional(QuestType.QuestState)
-- Variables
-- References
-- Private Functions
local function getCharacter(session: Session, characterId: string): Character?
	for _, character in session.Characters do
		if character.Id == characterId then
			return character
		end
	end
	return nil
end

local function getIfActiveCharacterChanged(session: Session, priorSession: Session): boolean
	return session.ActiveCharacterId ~= priorSession.ActiveCharacterId
		or session.ActiveIdentityKey ~= priorSession.ActiveIdentityKey
		or getCharacter(session, session.ActiveCharacterId) ~= getCharacter(priorSession, session.ActiveCharacterId)
end

-- every piece of a session is frozen by the time it gets here, so a new session is a clone with pieces swapped out
local function set(self: SessionService, player: Player, session: Session)
	local priorSession = self._Sessions[player]
	table.freeze(session)
	self._Sessions[player] = session
	if session.ActiveCharacterId ~= priorSession.ActiveCharacterId then
		AttributeDefinition.set(player, AttributeDefinition.ActiveCharacterId, session.ActiveCharacterId)
	end
	self.Changed:Fire(player, session, priorSession)
	if getIfActiveCharacterChanged(session, priorSession) then
		self.ActiveCharacterChanged:Fire(player)
	end
end

local function add(self: SessionService, player: Player)
	if self._Sessions[player] then
		return
	end
	local characters = CharacterSlotUtil.newStarters()
	local session: Session = {
		Characters = characters,
		ActiveCharacterId = characters[1].Id,
		ActiveIdentityKey = "Main",
		ArtifactIds = table.freeze({}),
		Inventory = BaseConstructor.newInventory(),
	}
	table.freeze(session)
	self._Sessions[player] = session
	-- the balances, the power limit + every other scalar start out as their definitions say
	AttributeDefinition.setDefaults(player, "Player")
	AttributeDefinition.set(player, AttributeDefinition.ActiveCharacterId, session.ActiveCharacterId)
	self.Added:Fire(player)
end

local function remove(self: SessionService, player: Player)
	if not self._Sessions[player] then
		return
	end
	self.Removing:Fire(player)
	self._Sessions[player] = nil
	self._IsInMenu[player] = nil
end

local function clip(text: string, maxLength: number): string?
	local length = utf8.len(text)
	if not length then
		return nil
	end
	if length <= maxLength then
		return text
	end
	local cutOff = utf8.offset(text, maxLength + 1)
	return if cutOff then string.sub(text, 1, cutOff - 1) else text
end

local function filterText(player: Player, text: string): Result<string, string>
	local f = Future.timeout(TextFilterUtil.filter(text, player.UserId), FILTER_TIMEOUT)
	if f.IsCanceled then
		return Result.err(`the filter took too long`)
	end
	return f.Value
end

-- yields. a text the slot already holds went through the filter when it was stored, so it's kept as it is + it's
-- what the slot falls back to when the filter has no answer
local function filterProfileText(
	player: Player,
	text: string,
	maxLength: number,
	priorText: string
): Result<string, string>
	local clippedText = clip(text, maxLength)
	if not clippedText then
		return Result.err(`a text of the character can't be read`)
	end
	if clippedText == "" or clippedText == priorText then
		return Result.ok(clippedText)
	end
	local filterRes = filterText(player, clippedText)
	if filterRes.IsErr then
		warn(`text of {player.Name} kept as it was: {filterRes.Value}`)
		return Result.ok(priorText)
	end
	return filterRes
end

local function filterProfile(player: Player, profile: Profile, priorProfile: Profile): Result<Profile, string>
	local nameRes = filterProfileText(player, profile.Name, MAX_NAME_LENGTH, priorProfile.Name)
	if nameRes.IsErr then
		return nameRes
	end
	local backstoryRes = filterProfileText(player, profile.Backstory, MAX_BACKSTORY_LENGTH, priorProfile.Backstory)
	if backstoryRes.IsErr then
		return backstoryRes
	end
	return Result.ok({
		-- a name the filter blanked out reads as unset, the name tag shows the user name for it
		Name = if string.match(nameRes.Value, "^#+$") then "" else nameRes.Value,
		Backstory = backstoryRes.Value,
		Alignment = profile.Alignment,
	})
end

local function getPowers(character: Character, powerLimit: number): Result<{ Power }, string>
	if #character.Powers > powerLimit then
		return Result.err(`a character holds up to {powerLimit} powers`)
	end
	local out: { Power } = {}
	for _, power in character.Powers do
		if PowerDefinition.get(power.Id).IsErr then
			return Result.err(`no power "{power.Id}"`)
		end
		for _, other in out do
			if other.Id == power.Id then
				return Result.err(`power "{power.Id}" is held twice`)
			end
		end
		table.insert(out, { Id = power.Id })
	end
	return Result.ok(out)
end

local function getPowerSkins(identity: Identity, powers: { Power }): { [string]: PowerSkin }
	local out: { [string]: PowerSkin } = {}
	for _, power in powers do
		local powerSkin = identity.PowerSkins[power.Id]
		local definitionRes = PowerDefinition.get(power.Id)
		if not powerSkin or powerSkin.ColorGroups.Primary == nil or definitionRes.IsErr then
			continue
		end
		local colorOpt = PowerDefinition.getColor(definitionRes.Value, powerSkin.ColorGroups.Primary)
		if colorOpt.IsSome then
			out[power.Id] = {
				Id = power.Id,
				ColorGroups = {
					Primary = colorOpt.Value,
				},
			}
		end
	end
	return out
end

-- artifacts are unlocked, a client can't wear one into a save it was never granted
local function getUnownedArtifactId(appearance: Appearance, artifactIds: { string }): string?
	for _, item in appearance.Items do
		local itemDefIndexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
		if
			itemDefIndexRes.IsOk
			and itemDefIndexRes.Value.Category == ARTIFACT_CATEGORY
			and not table.find(artifactIds, item.DefinitionId)
		then
			return item.DefinitionId
		end
	end
	return nil
end

local function getIfMultiHair(appearance: Appearance): boolean
	local count = 0
	for _, item in appearance.Items do
		local itemDefIndexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
		if itemDefIndexRes.IsOk and itemDefIndexRes.Value.Category == HAIR_CATEGORY then
			count += 1
		end
	end
	return count > 1
end

local function newIdentity(
	identity: Identity,
	profile: Profile,
	powers: { Power },
	artifactIds: { string },
	entitlements: { EntitlementKey }
): Result<Identity, string>
	local appearance = AppearanceConstructor.fix(identity.Appearance)
	local artifactId = getUnownedArtifactId(appearance, artifactIds)
	if artifactId then
		return Result.err(`artifact "{artifactId}" isn't owned`)
	end
	if getIfMultiHair(appearance) and not table.find(entitlements, "MultiHair") then
		return Result.err(`more than one hair needs the multi hair pass`)
	end
	return Result.ok({
		Profile = profile,
		PowerSkins = getPowerSkins(identity, powers),
		Appearance = appearance,
	})
end

-- yields. nothing a client hands in is stored as it came, the slot keeps its id + takes what's left of the rest
local function save(self: SessionService, player: Player, edited: Character): Result<Character, string>
	local priorSession = self._Sessions[player]
	local prior = priorSession and getCharacter(priorSession, edited.Id)
	local main, secret = edited.Identities.Main, edited.Identities.Secret
	local priorSecret = prior and prior.Identities.Secret
	if not prior or not secret or not priorSecret then
		return Result.err(`no slot holds the character`)
	end
	-- the text goes first: the filter yields, everything after it reads the session the way it is by then
	local mainProfileRes = filterProfile(player, main.Profile, prior.Identities.Main.Profile)
	if mainProfileRes.IsErr then
		return mainProfileRes
	end
	local secretProfileRes = filterProfile(player, secret.Profile, priorSecret.Profile)
	if secretProfileRes.IsErr then
		return secretProfileRes
	end
	local session = self._Sessions[player]
	if not session or not getCharacter(session, edited.Id) then
		return Result.err(`no slot holds the character`)
	end
	local entitlements = self:GetEntitlements(player)
	local powersRes = getPowers(edited, ProductDefinition.getPowerLimit(entitlements))
	if powersRes.IsErr then
		return powersRes
	end
	local mainRes = newIdentity(main, mainProfileRes.Value, powersRes.Value, session.ArtifactIds, entitlements)
	if mainRes.IsErr then
		return mainRes
	end
	local secretRes = newIdentity(secret, secretProfileRes.Value, powersRes.Value, session.ArtifactIds, entitlements)
	if secretRes.IsErr then
		return secretRes
	end
	return self:SetCharacter(player, {
		Id = edited.Id,
		Powers = powersRes.Value,
		Identities = {
			Main = mainRes.Value,
			Secret = secretRes.Value,
		},
	})
end
-- Class
local SessionService = {} :: SessionServiceImpl
SessionService.__index = SessionService

-- the session is frozen, a write goes through one of the setters
function SessionService:Get(player: Player): Option<Session>
	return Option.from(self._Sessions[player])
end

function SessionService:GetActiveCharacter(player: Player): Option<Character>
	local session = self._Sessions[player]
	return Option.from(if session then getCharacter(session, session.ActiveCharacterId) else nil)
end

function SessionService:GetIfInMenu(player: Player): boolean
	return self._IsInMenu[player] == true
end

-- writes a character the server put together over the slot with its id, an id no slot holds becomes a new last slot.
-- nothing is filtered or checked against what the player owns, that's only done for what a client hands in
function SessionService:SetCharacter(player: Player, character: Character): Result<Character, string>
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local session = self._Sessions[player]
	if not session then
		return Result.err(`{player.Name} has no session`)
	end
	local success, msg = CharacterType.Character(character)
	if not success then
		return Result.err(`bad character: {msg}`)
	end
	if character.Id == "" then
		return Result.err(`the character has no id`)
	end
	TableUtil.deepFreeze(character)
	local characters = table.clone(session.Characters)
	local index = #characters + 1
	for i, other in characters do
		if other.Id == character.Id then
			index = i
			break
		end
	end
	characters[index] = character
	table.freeze(characters)
	local out = table.clone(session)
	out.Characters = characters
	set(self, player, out)
	NetworkService:Fire(RemoteDefinition.CharacterChanged, player, character)
	return Result.ok(character)
end

function SessionService:SetActiveCharacter(player: Player, characterId: string): Result<true, string>
	local session = self._Sessions[player]
	if not session then
		return Result.err(`{player.Name} has no session`)
	end
	if not getCharacter(session, characterId) then
		return Result.err(`no slot holds the character`)
	end
	local out = table.clone(session)
	out.ActiveCharacterId = characterId
	out.ActiveIdentityKey = "Main"
	set(self, player, out)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function SessionService:SetActiveIdentity(player: Player, identityKey: IdentityKey): Result<true, string>
	local session = self._Sessions[player]
	local character = session and getCharacter(session, session.ActiveCharacterId)
	if not session or not character then
		return Result.err(`{player.Name} has no active character`)
	end
	if not character.Identities[identityKey] then
		return Result.err(`the character has no "{identityKey}" identity`)
	end
	local out = table.clone(session)
	out.ActiveIdentityKey = identityKey
	set(self, player, out)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function SessionService:SetArtifactIds(player: Player, artifactIds: { string }): Result<true, string>
	local session = self._Sessions[player]
	if not session then
		return Result.err(`{player.Name} has no session`)
	end
	local success, msg = isArtifactIds(artifactIds)
	if not success then
		return Result.err(`bad artifact ids: {msg}`)
	end
	local out = table.clone(session)
	out.ArtifactIds = table.freeze(table.clone(artifactIds))
	set(self, player, out)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function SessionService:SetInventory(player: Player, inventory: BaseInventory): Result<true, string>
	local session = self._Sessions[player]
	if not session then
		return Result.err(`{player.Name} has no session`)
	end
	local success, msg = BaseType.BaseInventory(inventory)
	if not success then
		return Result.err(`bad inventory: {msg}`)
	end
	TableUtil.deepFreeze(inventory)
	local out = table.clone(session)
	out.Inventory = inventory
	set(self, player, out)
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

-- the balances + the entitlements are scalars, so they're kept in the attributes of the player every client reads
function SessionService:GetBalance(player: Player, currency: PseudoEnum.Currency): number
	return AttributeDefinition.get(player, AttributeDefinition.fromCurrency(currency))
end

function SessionService:SetBalance(player: Player, currency: PseudoEnum.Currency, balance: number): Result<true, string>
	if not self._Sessions[player] then
		return Result.err(`{player.Name} has no session`)
	end
	local success, msg = EconomyType.Balance(balance)
	if not success then
		return Result.err(`bad balance: {msg}`)
	end
	AttributeDefinition.set(player, AttributeDefinition.fromCurrency(currency), balance)
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

function SessionService:GetEntitlements(player: Player): { EntitlementKey }
	return AttributeDefinition.getEntitlements(player)
end

-- what the entitlement unlocks comes with it: the power limit goes up + the extra slots are handed out
function SessionService:GrantEntitlement(player: Player, key: EntitlementKey): Result<true, string>
	local session = self._Sessions[player]
	if not session then
		return Result.err(`{player.Name} has no session`)
	end
	AttributeDefinition.set(player, AttributeDefinition.fromEntitlement(key), true)
	local entitlements = AttributeDefinition.getEntitlements(player)
	AttributeDefinition.set(player, AttributeDefinition.PowerLimit, ProductDefinition.getPowerLimit(entitlements))
	for _ = #session.Characters + 1, ProductDefinition.getCharacterSlotCount(entitlements) do
		local characterRes = self:SetCharacter(player, CharacterSlotUtil.newBlank())
		if characterRes.IsErr then
			return characterRes
		end
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

return ServiceLocker(function(): SessionService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		Added = Signal.new() :: Signal.Signal<Player>,
		Removing = Signal.new() :: Signal.Signal<Player>,
		Changed = Signal.new() :: Signal.Signal<Player, Session, Session>,
		ActiveCharacterChanged = Signal.new() :: Signal.Signal<Player>,
		InMenuChanged = Signal.new() :: Signal.Signal<Player, boolean>,
		_Sessions = {},
		_IsInMenu = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, SessionService)

	NetworkService:Handle(RemoteDefinition.GetSession, function(player: Player): Result<Session, string>
		-- a client can ask before the server got to its player, it's kept waiting rather than turned down
		local startTime = os.clock()
		while
			self.IsInitialized
			and not self._Sessions[player]
			and player.Parent ~= nil
			and os.clock() - startTime < SESSION_TIMEOUT
		do
			task.wait()
		end
		local session = if self.IsInitialized then self._Sessions[player] else nil
		if not session then
			return Result.err(`{player.Name} has no session`)
		end
		return Result.ok(session)
	end)
	NetworkService:Handle(
		RemoteDefinition.SelectCharacter,
		function(player: Player, characterId: string): Result<true, string>
			return self:SetActiveCharacter(player, characterId)
		end
	)
	NetworkService:Handle(
		RemoteDefinition.SaveCharacter,
		function(player: Player, character: Character): Result<Character, string>
			return save(self, player, character)
		end
	)
	NetworkService:Handle(RemoteDefinition.FilterText, function(player: Player, text: string): Result<string, string>
		local clippedText = clip(text, MAX_BACKSTORY_LENGTH)
		if not clippedText then
			return Result.err(`the text can't be read`)
		end
		if clippedText == "" then
			return Result.ok(clippedText)
		end
		local filterRes = filterText(player, clippedText)
		if filterRes.IsErr then
			-- what the filter threw isn't a line a menu can show
			warn(`text of {player.Name} wasn't filtered: {filterRes.Value}`)
			return Result.err(`the text couldn't be filtered`)
		end
		return filterRes
	end)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.SetInMenu, function(player: Player, isInMenu: boolean)
			if not self._Sessions[player] or self:GetIfInMenu(player) == isInMenu then
				return
			end
			self._IsInMenu[player] = if isInMenu then true else nil
			self.InMenuChanged:Fire(player, isInMenu)
		end)
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.SetTutorialEnabled, function(player: Player, isEnabled: boolean)
			AttributeDefinition.set(player, AttributeDefinition.IsTutorialEnabled, isEnabled)
		end)
	)

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
		add(self, player)
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
