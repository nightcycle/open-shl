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
local AppearanceUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local TransitionDefinition = require("@game/ReplicatedStorage/Shared/Definition/Transition")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
type Option<V> = TypeUnionLib.Option<V>
type Appearance = AppearanceType.Appearance
type Power = CharacterType.Power
type IdentityKey = CharacterType.IdentityKey
type EffectDefinition = TransitionDefinition.EffectDefinition
type Look = {
	IdentityKey: IdentityKey,
	PersonaName: string,
	Appearance: Appearance,
	Powers: { Power },
}
type AvatarServiceImpl = {
	__index: AvatarServiceImpl,
	Dress: (self: AvatarService, player: Player) -> (),
	PlayEffect: (self: AvatarService, character: Model, effect: EffectDefinition) -> (),
	GetAppearance: (self: AvatarService, player: Player) -> Option<Appearance>,
	GetIfMasked: (self: AvatarService, player: Player) -> boolean,
	SetMasked: (self: AvatarService, player: Player, isMasked: boolean) -> (),
}
export type AvatarService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- the avatar of a player wears a new set of items, whatever else sits on it has to be put back on
		Dressed: Signal.Signal<Player, Model>,
		_IsUnmasked: { [Player]: true? },
		_PlayerConnections: { [Player]: { RBXScriptConnection } },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: AvatarServiceImpl
))
-- Constants
local DRESS_TIMEOUT = 20
local EFFECT_NAME = "TransformationEffect"
-- Variables
-- References
-- Private Functions
local function getLook(self: AvatarService, player: Player): Option<Look>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	local characterOpt = SessionService:GetActiveCharacter(player)
	if sessionOpt.IsNone or characterOpt.IsNone then
		return Option.none()
	end
	local character = characterOpt.Value
	local identityKey: IdentityKey = sessionOpt.Value.ActiveIdentityKey
	local identity = character.Identities[identityKey]
	if not identity then
		return Option.none()
	end
	local look: Look = {
		IdentityKey = identityKey,
		PersonaName = identity.Profile.Name,
		Appearance = identity.Appearance,
		Powers = character.Powers,
	}
	local secret = character.Identities.Secret
	if identityKey == "Main" and self._IsUnmasked[player] and secret then
		-- a hero with the mask off answers to their civilian name
		look.PersonaName = secret.Profile.Name
		look.Appearance = AppearanceUtil.unmask(identity.Appearance, secret.Appearance)
	end
	return Option.some(look)
end

-- the tools do nothing yet, they only fill the hotbar in the order the character holds its powers
local function newTool(definition: PowerDefinition.PowerDefinition): Tool
	local icon = definition.Icon
	local tool = Instance.new("Tool")
	tool.Name = definition.Name
	tool.ToolTip = definition.Name
	tool.TextureId = if icon.Type == "Decal" then icon.Url else icon.SheetUrl
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool:SetAttribute(PowerDefinition.TOOL_ID_ATTRIBUTE, definition.Id)
	return tool
end

local function giveTools(player: Player, character: Model, powers: { Power })
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		warn(`{player.Name} has no backpack to hold their powers`)
		return
	end
	for _, holder: Instance in { backpack :: Instance, character } do
		for _, v in holder:GetChildren() do
			if v:IsA("Tool") and v:GetAttribute(PowerDefinition.TOOL_ID_ATTRIBUTE) ~= nil then
				v:Destroy()
			end
		end
	end
	for _, power in powers do
		local definitionRes = PowerDefinition.get(power.Id)
		if definitionRes.IsErr then
			warn(`power err: {definitionRes.Value}`)
			continue
		end
		newTool(definitionRes.Value).Parent = backpack
	end
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

local function onCharacter(self: AvatarService, player: Player, character: Model)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	-- health + energy start out full, nothing takes them down for as long as the powers do nothing
	AttributeDefinition.setDefaults(character, "Character")
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		-- the game draws its own name tag, the stock one would give the user name away
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		-- npc humanoids don't get a stock tag on this player's screen either
		humanoid.NameDisplayDistance = 0
		humanoid.HealthDisplayDistance = 0
	end
	setInMenu(player, character, SessionService:GetIfInMenu(player))
	self:Dress(player)
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
	AttributeDefinition.set(character, AttributeDefinition.IdentityKey, look.IdentityKey)
	AttributeDefinition.set(character, AttributeDefinition.IsMasked, self:GetIfMasked(player))
	giveTools(player, character, look.Powers)
	-- the description is a web call, whoever asked for the dress can't wait on it
	task.spawn(function()
		local f = Future.timeout(AppearanceUtil.apply(character, look.Appearance), DRESS_TIMEOUT)
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

function AvatarService:GetIfMasked(player: Player): boolean
	return self._IsUnmasked[player] == nil
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

return ServiceLocker(function(): AvatarService
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		Dressed = Signal.new() :: Signal.Signal<Player, Model>,
		_IsUnmasked = {} :: { [Player]: true? },
		_PlayerConnections = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, AvatarService)

	local activeCharacterConnection = SessionService.ActiveCharacterChanged:Connect(function(player: Player)
		self._IsUnmasked[player] = nil
		self:Dress(player)
	end)
	local inMenuConnection = SessionService.InMenuChanged:Connect(function(player: Player, isInMenu: boolean)
		if player.Character then
			setInMenu(player, player.Character, isInMenu)
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
