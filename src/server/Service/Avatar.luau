--!strict
-- Services
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Option = TypeUnionLib.Option
local Future = TypeUnionLib.Future
-- Modules
local AbilityService = require("@game/ServerScriptService/Server/Service/Ability")
local AppearanceUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CharacterEditorDefinition = require("@game/ReplicatedStorage/Shared/Definition/CharacterEditor")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local SpawnDefinition = require("@game/ServerScriptService/Server/Definition/Spawn")
local TransitionDefinition = require("@game/ReplicatedStorage/Shared/Definition/Transition")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterEditorType = require("@game/ReplicatedStorage/Shared/Type/CharacterEditor")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local IdentityType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity")
type Option<V> = TypeUnionLib.Option<V>
type Appearance = AppearanceType.Appearance
type Item = AppearanceType.Item
type Character = CharacterType.Character
type PowerColorSource = CharacterEditorType.PowerColorSource
type Grant = AbilityType.Grant
type IdentityKey = CharacterType.IdentityKey
type EffectDefinition = TransitionDefinition.EffectDefinition
type Look = {
	IdentityKey: IdentityKey,
	PersonaName: string,
	Appearance: Appearance,
	Grants: { Grant },
}
-- what the server puts a player in over whoever they picked to be: worn, never saved
export type Costume = {
	IdentityKey: IdentityKey, -- who's out for as long as it's on
	Items: { Item }, -- each takes the place of whatever that identity wears of its category
	IsPowerless: boolean, -- none of the character's powers are handed out
}
type AvatarServiceImpl = {
	__index: AvatarServiceImpl,
	Dress: (self: AvatarService, player: Player) -> (),
	Arm: (self: AvatarService, player: Player) -> (),
	PlayEffect: (self: AvatarService, character: Model, effect: EffectDefinition) -> (),
	GetAppearance: (self: AvatarService, player: Player) -> Option<Appearance>,
	GetCostume: (self: AvatarService, player: Player) -> Option<Costume>,
	GetIfMasked: (self: AvatarService, player: Player) -> boolean,
	GetIfHeld: (self: AvatarService, player: Player) -> boolean,
	SetMasked: (self: AvatarService, player: Player, isMasked: boolean) -> (),
	SetCostume: (self: AvatarService, player: Player, costume: Costume?) -> (),
}
export type AvatarService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- the avatar of a player wears a new set of items, whatever else sits on it has to be put back on
		Dressed: Signal.Signal<Player, Model>,
		-- an avatar came in. its attributes are the ones every avatar starts out with, nobody saw it yet
		Spawned: Signal.Signal<Player, Model>,
		_IsUnmasked: { [Player]: true? },
		_Costumes: { [Player]: Costume? },
		-- the avatar of whoever came in behind a menu + wasn't let out of it since
		_HeldAvatars: { [Player]: Model? },
		_PlayerConnections: { [Player]: { RBXScriptConnection } },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: AvatarServiceImpl
))
-- Constants
local DRESS_TIMEOUT = 20
local EFFECT_NAME = "TransformationEffect"
-- nil in a game whose powers are colored by a pick of their own
local POWER_COLOR_SOURCE = CharacterEditorDefinition.POWER_COLOR_SOURCE
-- nil in a game where an avatar comes back as whoever it was
local SPAWN_IDENTITY_KEY: IdentityKey? = SpawnDefinition.IDENTITY_KEY
-- nil in a game where an avatar that's let out of the menu it came in behind is let out bare
local ENTRY_SHIELD_DURATION: number? = SpawnDefinition.ENTRY_SHIELD_DURATION
-- nil in a game that draws the health of an avatar itself
local HEALTH_DISPLAY_DISTANCE: number? = SpawnDefinition.HEALTH_DISPLAY_DISTANCE
-- if a hero with the mask off answers to their civilian name
local IS_UNMASKED_RENAMED: boolean = GameDefinition.tune(true, {
	-- its hero kept their name whatever they showed of their head
	shl1 = false,
})
-- Variables
-- References
-- Private Functions
-- the two colors of the item the powers of the game are colored by, whichever identity is out. an item without
-- them, or none at all, leaves a power in the colors it comes in
local function getSourceColors(character: Character, source: PowerColorSource): (Color3?, Color3?)
	local identity = character.Identities[source.IdentityKey]
	if not identity then
		return nil, nil
	end
	for _, item in identity.Appearance.Items do
		local itemDefIndexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
		if
			itemDefIndexRes.IsErr
			or itemDefIndexRes.Value.Group ~= source.Group
			or itemDefIndexRes.Value.Category ~= source.Category
		then
			continue
		end
		local primary, secondary = item.TextureGroups[source.Primary], item.TextureGroups[source.Secondary]
		return if primary then primary.Color else nil, if secondary then secondary.Color else nil
	end
	return nil, nil
end

-- an ability comes in the color the identity wears it in, or in the colors of what the game takes them from. a game
-- that only takes them for some of its powers has the others come the way a game without a source has all of them
local function getGrants(character: Character, identity: IdentityType.Identity): { Grant }
	local grants: { Grant } = {}
	local sourceColor: Color3?, sourceSecondaryColor: Color3? = nil, nil
	local sourcePowerIds: { string }? = nil
	if POWER_COLOR_SOURCE then
		sourceColor, sourceSecondaryColor = getSourceColors(character, POWER_COLOR_SOURCE)
		sourcePowerIds = POWER_COLOR_SOURCE.PowerIds
	end
	for _, power in character.Powers do
		local definitionRes = PowerDefinition.get(power.Id)
		if definitionRes.IsErr then
			warn(`power err: {definitionRes.Value}`)
			continue
		end
		local isSourced = POWER_COLOR_SOURCE ~= nil
			and (sourcePowerIds == nil or table.find(sourcePowerIds, power.Id) ~= nil)
		local color: Color3? = if isSourced then sourceColor else nil
		if not isSourced then
			local powerSkin = identity.PowerSkins[power.Id]
			local colorOpt =
				PowerDefinition.getColor(definitionRes.Value, if powerSkin then powerSkin.ColorGroups.Primary else nil)
			color = if colorOpt.IsSome then colorOpt.Value else nil
		end
		table.insert(
			grants,
			table.freeze({
				Id = power.Id,
				Color = color,
				SecondaryColor = if isSourced then sourceSecondaryColor else nil,
			})
		)
	end
	return table.freeze(grants)
end

-- the look with the items of a costume on, each in the place of whatever is worn of its category
local function wear(appearance: Appearance, items: { Item }): Appearance
	return FreezeUtil.delta(appearance, function(t: Appearance): Appearance
		for _, item in items do
			local indexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
			if indexRes.IsErr then
				continue
			end
			for i = #t.Items, 1, -1 do
				local wornIndexRes = ItemAppearanceDefinition.getIndex(t.Items[i].DefinitionId)
				if
					wornIndexRes.IsOk
					and wornIndexRes.Value.Group == indexRes.Value.Group
					and wornIndexRes.Value.Category == indexRes.Value.Category
				then
					table.remove(t.Items, i)
				end
			end
		end
		for _, item in items do
			table.insert(t.Items, item)
		end
		return t
	end)
end

local function getLook(self: AvatarService, player: Player): Option<Look>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	local characterOpt = SessionService:GetActiveCharacter(player)
	if sessionOpt.IsNone or characterOpt.IsNone then
		return Option.none()
	end
	local character = characterOpt.Value
	-- a costume says who's out, whoever the session has
	local costume = self._Costumes[player]
	local identityKey: IdentityKey = if costume then costume.IdentityKey else sessionOpt.Value.ActiveIdentityKey
	local identity = character.Identities[identityKey]
	if not identity then
		return Option.none()
	end
	-- an identity that doesn't carry the powers of its character is handed none of them, + neither is anybody in a
	-- costume that comes without
	local isArmed = PowerDefinition.getIfCarried(identityKey) and not (costume ~= nil and costume.IsPowerless)
	local look: Look = {
		IdentityKey = identityKey,
		PersonaName = identity.Profile.Name,
		Appearance = identity.Appearance,
		Grants = if isArmed then getGrants(character, identity) else table.freeze({}),
	}
	local secret = character.Identities.Secret
	if identityKey == "Main" and self._IsUnmasked[player] and secret then
		if IS_UNMASKED_RENAMED then
			look.PersonaName = secret.Profile.Name
		end
		look.Appearance = AppearanceUtil.unmask(identity.Appearance, secret.Appearance)
	end
	if costume then
		look.Appearance = wear(look.Appearance, costume.Items)
	end
	return Option.some(look)
end

-- yields. what the account of the player has on is asked for once, as their session starts: it's on no save. the
-- avatar that's out by the time the answer is in gets dressed once more
local function loadClothes(self: AvatarService, player: Player)
	-- a player of a test server has no account to ask about
	if player.UserId < 1 then
		return
	end
	local success, shirt, pants = pcall(function(): (number, number)
		local description = Players:GetHumanoidDescriptionFromUserIdAsync(player.UserId)
		local shirtId, pantsId = description.Shirt, description.Pants
		description:Destroy()
		return shirtId, pantsId
	end)
	if not success then
		-- the body stays the one of somebody who wears neither
		warn(`clothes err: {shirt}`)
		return
	end
	if not self.IsInitialized or not self._PlayerConnections[player] then
		return
	end
	AttributeDefinition.set(player, AttributeDefinition.ShirtAssetId, shirt)
	AttributeDefinition.set(player, AttributeDefinition.PantsAssetId, pants)
	self:Dress(player)
end

-- a player inside of a full screen menu isn't looking at their avatar, it stands still until they're back
local function setInMenu(player: Player, character: Model, isInMenu: boolean)
	AttributeDefinition.set(character, AttributeDefinition.IsInMenu, isInMenu)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return
	end
	rootPart.Anchored = isInMenu
	-- an avatar that's let go of is its player's to move again right away. left to the engine the server may hold on
	-- to it for a moment, where the floors a client built for itself (a residence) don't exist
	if not isInMenu and rootPart:IsDescendantOf(Workspace) then
		pcall(function()
			rootPart:SetNetworkOwner(player)
		end)
	end
end

-- an avatar that came in behind a menu is in the world from the first time it's let out of it. the force field its
-- spot handed it is long gone by then, a game can hand it another
local function release(self: AvatarService, player: Player, character: Model)
	if self._HeldAvatars[player] ~= character then
		return
	end
	self._HeldAvatars[player] = nil
	if ENTRY_SHIELD_DURATION then
		local forceField = Instance.new("ForceField")
		forceField.Parent = character
		Debris:AddItem(forceField, ENTRY_SHIELD_DURATION)
	end
end

local function onCharacter(self: AvatarService, player: Player, character: Model)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	-- health + energy start out full, nothing takes them down for as long as the powers do nothing
	AttributeDefinition.setDefaults(character, "Character")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- the game draws its own name tag, the stock one would give the user name away. a game that leaves health
		-- to the bar of the engine has it drawn over whoever is hurt, for whoever looks from close enough
		humanoid.DisplayDistanceType = if HEALTH_DISPLAY_DISTANCE
			then Enum.HumanoidDisplayDistanceType.Viewer
			else Enum.HumanoidDisplayDistanceType.None
		-- npc humanoids don't get a stock tag on this player's screen either
		humanoid.NameDisplayDistance = 0
		humanoid.HealthDisplayDistance = HEALTH_DISPLAY_DISTANCE or 0
		-- a body that falls apart as it dies has nothing left to act its death out with
		humanoid.BreakJointsOnDeath = false
	end
	local isInMenu = SessionService:GetIfInMenu(player)
	self._HeldAvatars[player] = if isInMenu then character else nil
	setInMenu(player, character, isInMenu)
	self.Spawned:Fire(player, character)
	-- a game can have an avatar come back as one identity whoever it went down as, + a costume that whoever heard of
	-- the avatar just now put its player in has it come in as its own. a session that's told to change who is out has
	-- the avatar dressed for it, which is the dress this one was about to get
	local costume = self._Costumes[player]
	local spawnIdentityKey: IdentityKey? = if costume then costume.IdentityKey else SPAWN_IDENTITY_KEY
	local sessionOpt = SessionService:Get(player)
	local isAnotherOut = sessionOpt.IsSome and sessionOpt.Value.ActiveIdentityKey ~= spawnIdentityKey
	if spawnIdentityKey and isAnotherOut then
		local identityRes = SessionService:SetActiveIdentity(player, spawnIdentityKey)
		if identityRes.IsOk then
			return
		end
		warn(`spawn err: {identityRes.Value}`)
	end
	self:Dress(player)
end

-- the spots a game has its avatars come in at hand out the force field of the engine for as long as the game says
local function setSpawns()
	local tag, shieldDuration = SpawnDefinition.TAG, SpawnDefinition.SHIELD_DURATION
	if not tag then
		return
	end
	local spots = MapDefinition.list(tag)
	-- the engine would drop everybody at the middle of the world instead
	if #spots == 0 then
		warn(`the map marks no spot for an avatar to come in at`)
	end
	if shieldDuration then
		for _, spot in spots do
			spot.Duration = shieldDuration
		end
	end
end

local function add(self: AvatarService, player: Player)
	if self._PlayerConnections[player] then
		return
	end
	local loadedAvatar: Model?
	self._PlayerConnections[player] = {
		player.CharacterAdded:Connect(function(character: Model)
			onCharacter(self, player, character)
		end),
		-- only matters where the place still loads the look of the user: it lands on top of the dress that
		-- started when the avatar spawned, so the avatar is dressed once more
		player.CharacterAppearanceLoaded:Connect(function(character: Model)
			if loadedAvatar == character then
				return
			end
			loadedAvatar = character
			self:Dress(player)
		end),
	}
	if player.Character then
		onCharacter(self, player, player.Character)
	end
	if AppearanceUtil.HAS_OWN_CLOTHES then
		task.spawn(loadClothes, self, player)
	end
end

local function remove(self: AvatarService, player: Player)
	local connections = self._PlayerConnections[player]
	if connections then
		for _, v in connections do
			v:Disconnect()
		end
	end
	self._PlayerConnections[player] = nil
	self._IsUnmasked[player] = nil
	self._Costumes[player] = nil
	self._HeldAvatars[player] = nil
end
-- Class
local AvatarService = {} :: AvatarServiceImpl
AvatarService.__index = AvatarService

-- puts the look of the player onto their avatar: the attributes + the tools right away, the items once the
-- avatar took the description. the newest dress of an avatar wins, an older one that's still going is dropped
function AvatarService:Dress(player: Player)
	local character = player.Character
	local lookOpt = getLook(self, player)
	if not character or lookOpt.IsNone then
		return
	end
	local look = lookOpt.Value
	AttributeDefinition.set(character, AttributeDefinition.PersonaName, look.PersonaName)
	-- the name is told on the player as well, for whoever lists everybody from where the avatar isn't in range
	AttributeDefinition.set(player, AttributeDefinition.ActivePersonaName, look.PersonaName)
	AttributeDefinition.set(player, AttributeDefinition.ActiveIdentityKey, look.IdentityKey)
	AttributeDefinition.set(character, AttributeDefinition.IdentityKey, look.IdentityKey)
	AttributeDefinition.set(character, AttributeDefinition.IsMasked, self:GetIfMasked(player))
	if AbilityService.IsInitialized then
		AbilityService:Grant(player, character, look.Grants)
	end
	-- the description is a web call, whoever asked for the dress can't wait on it
	task.spawn(function()
		local clothes = AppearanceUtil.getClothes(player)
		local f = Future.timeout(AppearanceUtil.apply(character, look.Appearance, clothes), DRESS_TIMEOUT)
		if f.IsCanceled then
			return
		end
		if f.Value.IsErr then
			for _, message in f.Value.Value do
				warn(`appearance err: {message}`)
			end
		end
		if self.IsInitialized and player.Character == character then
			self.Dressed:Fire(player, character)
		end
	end)
end

-- hands the avatar that's out the powers of its look + nothing else: for whoever was kept from them, without a dress
function AvatarService:Arm(player: Player)
	local character = player.Character
	local lookOpt = getLook(self, player)
	if not character or lookOpt.IsNone or not AbilityService.IsInitialized then
		return
	end
	AbilityService:Grant(player, character, lookOpt.Value.Grants)
end

-- what everybody sees of a transformation, the costume changes behind it
function AvatarService:PlayEffect(character: Model, effect: EffectDefinition)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart or not rootPart:IsA("BasePart") then
		return
	end
	local holder = Instance.new("Part")
	holder.Name = EFFECT_NAME
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.CanTouch = false
	holder.Transparency = 1
	holder.Size = Vector3.one
	holder.CFrame = rootPart.CFrame + effect.Offset

	if effect.Type == "Fire" then
		local fire = Instance.new("Fire")
		fire.Color = effect.Color
		fire.SecondaryColor = effect.SecondaryColor
		fire.Heat = effect.Heat
		fire.Size = effect.Size
		fire.Parent = holder
		task.delay(effect.EmitDuration, function()
			fire.Enabled = false
		end)
	else
		local smoke = Instance.new("Smoke")
		smoke.Color = effect.Color
		smoke.Opacity = effect.Opacity
		smoke.RiseVelocity = effect.RiseVelocity
		smoke.Size = effect.Size
		smoke.Parent = holder
		task.delay(effect.EmitDuration, function()
			smoke.Enabled = false
		end)
	end
	holder.Parent = character
	Debris:AddItem(holder, effect.Lifetime)
end

function AvatarService:GetAppearance(player: Player): Option<Appearance>
	local lookOpt = getLook(self, player)
	if lookOpt.IsNone then
		return Option.none()
	end
	return Option.some(lookOpt.Value.Appearance)
end

function AvatarService:GetCostume(player: Player): Option<Costume>
	return Option.from(self._Costumes[player])
end

function AvatarService:GetIfMasked(player: Player): boolean
	return self._IsUnmasked[player] == nil
end

-- if the avatar that's out came in behind a menu + hasn't been let out of it since: nobody met it in the world yet
function AvatarService:GetIfHeld(player: Player): boolean
	return player.Character ~= nil and self._HeldAvatars[player] == player.Character
end

-- only the super identity has a mask to take off, the mask is back on whenever the player becomes somebody else
function AvatarService:SetMasked(player: Player, isMasked: boolean)
	local lookOpt = getLook(self, player)
	if lookOpt.IsNone then
		return
	end
	local isMaskOn = isMasked or lookOpt.Value.IdentityKey ~= "Main"
	if isMaskOn == self:GetIfMasked(player) then
		return
	end
	self._IsUnmasked[player] = if isMaskOn then nil else true
	self:Dress(player)
end

-- only kept: nobody is dressed for it. the avatar that's out wears it from its next dress on, + keeps on what it has
-- of one that's taken off until the dress after. it goes with the session, + there's none for a player without one
function AvatarService:SetCostume(player: Player, costume: Costume?)
	if not self._PlayerConnections[player] then
		return
	end
	self._Costumes[player] = costume
end

return ServiceLocker(function(): AvatarService
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		Dressed = Signal.new() :: Signal.Signal<Player, Model>,
		Spawned = Signal.new() :: Signal.Signal<Player, Model>,
		_IsUnmasked = {} :: { [Player]: true? },
		_Costumes = {} :: { [Player]: Costume? },
		_HeldAvatars = {} :: { [Player]: Model? },
		_PlayerConnections = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, AvatarService)

	local activeCharacterConnection = SessionService.ActiveCharacterChanged:Connect(function(player: Player)
		self._IsUnmasked[player] = nil
		self:Dress(player)
	end)
	local inMenuConnection = SessionService.InMenuChanged:Connect(function(player: Player, isInMenu: boolean)
		local character = player.Character
		if character then
			setInMenu(player, character, isInMenu)
			if not isInMenu then
				release(self, player, character)
			end
		end
	end)
	local addedConnection = SessionService.Added:Connect(function(player: Player)
		add(self, player)
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		remove(self, player)
	end)
	table.insert(self._CleanUpCallbacks, function()
		activeCharacterConnection:Disconnect()
		inMenuConnection:Disconnect()
		addedConnection:Disconnect()
		removingConnection:Disconnect()
	end)
	-- before anybody is added: an avatar that's in already came in by what the map says
	setSpawns()
	for _, player in Players:GetPlayers() do
		if SessionService:Get(player).IsSome then
			add(self, player)
		end
	end

	table.insert(self._CleanUpCallbacks, function()
		for _, connections in self._PlayerConnections do
			for _, v in connections do
				v:Disconnect()
			end
		end
		self.Dressed:Destroy()
		self.Spawned:Destroy()
	end)

	return self
end, function(self: AvatarService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
