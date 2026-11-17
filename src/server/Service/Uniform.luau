--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local UniformDefinition = require("@game/ServerScriptService/Server/Definition/Uniform")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type Item = AppearanceType.Item
type ItemGroup = AppearanceType.ItemGroup
type TextureGroupKey = AppearanceType.TextureGroupKey
type IdentityKey = CharacterType.IdentityKey
type PlayerSave = SaveType.PlayerSave
type UniformDefinition = UniformDefinition.UniformDefinition
type UniformServiceImpl = {
	__index: UniformServiceImpl,
}
export type UniformService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_DressTimes: { [Player]: number }, -- when a prop last dressed a player, on the clock of os.clock
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: UniformServiceImpl
))
-- Constants
-- a uniform is what a civilian goes to work in, the hero keeps their costume
local IDENTITY_KEY: IdentityKey = "Secret"
local CLOTHING_GROUP: ItemGroup = "clothing"
-- the one kind of clothing that's part of a face rather than of an outfit
local KEPT_CATEGORY = "glasses"
-- seconds the props leave a player alone for once one of them dressed them. a touch is whatever the client of an
-- avatar says it is + two props stand close enough to be touched at once, each change is a save + a whole new dress
local DRESS_COOLDOWN = 0.5
-- Variables
-- References
-- Private Functions
local function getIfReplaced(item: Item, uniform: UniformDefinition): boolean
	-- an item is only ever worn once, so the one the uniform brings takes the place of the one that's on already
	for _, uniformItem in uniform.Items do
		if uniformItem.DefinitionId == item.DefinitionId then
			return true
		end
	end
	local indexRes = ItemAppearanceDefinition.getIndex(item.DefinitionId)
	return indexRes.IsOk and indexRes.Value.Group == CLOTHING_GROUP and indexRes.Value.Category ~= KEPT_CATEGORY
end

-- the uniform takes the place of the clothes, whatever else is worn stays on
local function wear(items: { Item }, uniform: UniformDefinition): { Item }
	local out: { Item } = {}
	for _, item in items do
		if not getIfReplaced(item, uniform) then
			table.insert(out, item)
		end
	end
	for _, item in uniform.Items do
		table.insert(out, item)
	end
	return out
end

local function getIfSameItem(item: Item, other: Item): boolean
	if item.DefinitionId ~= other.DefinitionId then
		return false
	end
	for key: TextureGroupKey in item.TextureGroups do
		local group, otherGroup = item.TextureGroups[key], other.TextureGroups[key]
		if
			not group
			or not otherGroup
			or group.Color ~= otherGroup.Color
			or group.Material ~= otherGroup.Material
			or group.Transparency ~= otherGroup.Transparency
		then
			return false
		end
	end
	for key: TextureGroupKey in other.TextureGroups do
		if not item.TextureGroups[key] then
			return false
		end
	end
	return true
end

local function getIfSame(items: { Item }, others: { Item }): boolean
	if #items ~= #others then
		return false
	end
	for index, item in items do
		if not getIfSameItem(item, others[index]) then
			return false
		end
	end
	return true
end

local function onTouched(self: UniformService, player: Player, uniform: UniformDefinition)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	local characterOpt = SessionService:GetActiveCharacter(player)
	if sessionOpt.IsNone or characterOpt.IsNone then
		return
	end
	if sessionOpt.Value.ActiveIdentityKey ~= IDENTITY_KEY or sessionOpt.Value.IsInMenu then
		return
	end
	local characterId = characterOpt.Value.Id
	local identity = characterOpt.Value.Identities[IDENTITY_KEY]
	if not identity then
		return
	end
	local dressTime = self._DressTimes[player]
	if dressTime and os.clock() - dressTime < DRESS_COOLDOWN then
		return
	end
	-- a prop is touched many times over while somebody stands on it, the save is only written for the first
	local items = wear(identity.Appearance.Items, uniform)
	if getIfSame(items, identity.Appearance.Items) then
		return
	end
	self._DressTimes[player] = os.clock()
	-- the avatar is dressed again by whoever listens to the session, the same as after any other change of clothes
	local saveRes = SessionService:Update(player, function(save: PlayerSave): PlayerSave?
		for _, character in save.Characters do
			local savedIdentity = character.Identities[IDENTITY_KEY]
			if character.Id == characterId and savedIdentity then
				savedIdentity.Appearance.Items = items
				return save
			end
		end
		return nil
	end)
	if saveRes.IsErr then
		warn(`uniform err: {saveRes.Value}`)
	end
end
-- Class
local UniformService = {} :: UniformServiceImpl
UniformService.__index = UniformService

return ServiceLocker(function(): UniformService
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_DressTimes = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, UniformService)

	for _, prop in MapDefinition.list(MapDefinition.Uniform) do
		local idRes = MapDefinition.get(prop, MapDefinition.UniformId)
		if idRes.IsErr then
			warn(`uniform err: {idRes.Value}`)
			continue
		end
		local uniformRes = UniformDefinition.get(idRes.Value)
		if uniformRes.IsErr then
			warn(`uniform err: {uniformRes.Value}`)
			continue
		end
		local uniform = uniformRes.Value
		for _, part in prop:GetDescendants() do
			if not part:IsA("BasePart") then
				continue
			end
			table.insert(
				self._Connections,
				part.Touched:Connect(function(hit: BasePart)
					local avatar = hit.Parent
					local player = if avatar and avatar:IsA("Model")
						then Players:GetPlayerFromCharacter(avatar)
						else nil
					local humanoid = avatar and avatar:FindFirstChildOfClass("Humanoid")
					if player and humanoid and humanoid.Health > 0 then
						onTouched(self, player, uniform)
					end
				end)
			)
		end
	end

	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		self._DressTimes[player] = nil
	end)
	table.insert(self._CleanUpCallbacks, function()
		removingConnection:Disconnect()
	end)

	return self
end, function(self: UniformService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
