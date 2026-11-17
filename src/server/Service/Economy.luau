--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local FurnitureDefinition = require("@game/ReplicatedStorage/Shared/Definition/Furniture")
local ItemAppearanceDefinition = require("@game/ReplicatedStorage/Shared/Definition/Appearance/Item")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local ThemeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Theme")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type Result<V, E> = TypeUnionLib.Result<V, E>
type BaseInventory = BaseType.BaseInventory
type Purchasable = {
	Id: string,
	Name: string,
	Price: number,
	Currency: PseudoEnum.Currency,
}
type EconomyServiceImpl = {
	__index: EconomyServiceImpl,
	Grant: (
		self: EconomyService,
		player: Player,
		currency: PseudoEnum.Currency,
		amount: number
	) -> Result<true, string>,
	Spend: (
		self: EconomyService,
		player: Player,
		currency: PseudoEnum.Currency,
		amount: number
	) -> Result<true, string>,
	GrantArtifact: (self: EconomyService, player: Player, rarity: PseudoEnum.Rarity) -> Result<string, string>,
}
export type EconomyService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Random: Random,
		-- when a user last got the daily reward, by user id so that leaving + coming back doesn't hand out another
		_DailyRewardTimes: { [number]: number },
		_DailyRewardThreads: { [Player]: thread },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: EconomyServiceImpl
))
-- Constants
local DAILY_REWARD = ProductDefinition.DAILY_REWARD
-- how long after a player joined the daily reward is looked at
local DAILY_REWARD_DELAY = 20
local ARTIFACT_GROUP: AppearanceType.ItemGroup = "costume"
local ARTIFACT_CATEGORY = "artifacts"
-- the colossal bladepack is a gift, it's never drawn
local UNDRAWN_ARTIFACT_IDS = table.freeze({ "costume_artifacts_colossal-bladepack" })
local isAmount = EconomyType.Balance
-- Variables
-- References
-- Private Functions
local function setInventory(player: Player, inventory: BaseInventory): Result<true, string>
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local inventoryRes = SessionService:SetInventory(player, inventory)
	if inventoryRes.IsErr then
		return inventoryRes
	end
	NetworkService:Fire(RemoteDefinition.InventoryChanged, player, inventory)
	return inventoryRes
end

local function purchase(
	self: EconomyService,
	player: Player,
	ownedIds: { string },
	purchasable: Purchasable
): Result<{ string }, string>
	if table.find(ownedIds, purchasable.Id) then
		return Result.err(`"{purchasable.Name}" is already owned`)
	end
	local spendRes = self:Spend(player, purchasable.Currency, purchasable.Price)
	if spendRes.IsErr then
		return spendRes
	end
	local out = table.clone(ownedIds)
	table.insert(out, purchasable.Id)
	return Result.ok(out)
end

local function purchaseFurniture(self: EconomyService, player: Player, furnitureId: string): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	local definitionRes = FurnitureDefinition.get(furnitureId)
	if definitionRes.IsErr then
		return definitionRes
	end
	local inventory = sessionOpt.Value.Inventory
	local furnitureIdsRes = purchase(self, player, inventory.FurnitureIds, definitionRes.Value)
	if furnitureIdsRes.IsErr then
		return furnitureIdsRes
	end
	return setInventory(player, {
		FurnitureIds = furnitureIdsRes.Value,
		ThemeIds = table.clone(inventory.ThemeIds),
	})
end

local function purchaseTheme(self: EconomyService, player: Player, themeId: string): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	local definitionRes = ThemeDefinition.get(themeId)
	if definitionRes.IsErr then
		return definitionRes
	end
	local inventory = sessionOpt.Value.Inventory
	local themeIdsRes = purchase(self, player, inventory.ThemeIds, definitionRes.Value)
	if themeIdsRes.IsErr then
		return themeIdsRes
	end
	return setInventory(player, {
		FurnitureIds = table.clone(inventory.FurnitureIds),
		ThemeIds = themeIdsRes.Value,
	})
end

-- todo: real robux purchases, for now the product is just handed over
local function purchaseProduct(self: EconomyService, player: Player, productId: string): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local definitionRes = ProductDefinition.get(productId)
	if definitionRes.IsErr then
		return definitionRes
	end
	local definition = definitionRes.Value
	local grant = definition.Grant
	if grant.Type == "Currency" then
		return self:Grant(player, grant.Currency, grant.Amount)
	elseif grant.Type == "Artifact" then
		local artifactRes = self:GrantArtifact(player, grant.Rarity)
		if artifactRes.IsErr then
			return artifactRes
		end
		return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
	else
		if table.find(SessionService:GetEntitlements(player), grant.Key) then
			return Result.err(`"{definition.Name}" is already owned`)
		end
		return SessionService:GrantEntitlement(player, grant.Key)
	end
end

-- a few gems once per rolling day. nothing is saved yet, so the day only lasts as long as the server
local function grantDailyReward(self: EconomyService, player: Player)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	if SessionService:Get(player).IsNone then
		return
	end
	local now = os.time()
	local priorTime = self._DailyRewardTimes[player.UserId]
	if priorTime and now - priorTime < DAILY_REWARD.INTERVAL then
		return
	end
	local grantRes = self:Grant(player, DAILY_REWARD.CURRENCY, DAILY_REWARD.AMOUNT)
	if grantRes.IsErr then
		warn(`daily reward err: {grantRes.Value}`)
		return
	end
	self._DailyRewardTimes[player.UserId] = now
	NetworkService:Fire(RemoteDefinition.DailyRewardGranted, player, {
		Currency = DAILY_REWARD.CURRENCY,
		Amount = DAILY_REWARD.AMOUNT,
	})
end

local function add(self: EconomyService, player: Player)
	if self._DailyRewardThreads[player] then
		return
	end
	self._DailyRewardThreads[player] = task.delay(DAILY_REWARD_DELAY, function()
		self._DailyRewardThreads[player] = nil
		grantDailyReward(self, player)
	end)
end

local function remove(self: EconomyService, player: Player)
	local thread = self._DailyRewardThreads[player]
	if thread and coroutine.status(thread) == "suspended" then
		task.cancel(thread)
	end
	self._DailyRewardThreads[player] = nil
end
-- Class
local EconomyService = {} :: EconomyServiceImpl
EconomyService.__index = EconomyService

function EconomyService:Grant(player: Player, currency: PseudoEnum.Currency, amount: number): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local success, msg = isAmount(amount)
	if not success then
		return Result.err(`bad amount: {msg}`)
	end
	return SessionService:SetBalance(player, currency, SessionService:GetBalance(player, currency) + amount)
end

function EconomyService:Spend(player: Player, currency: PseudoEnum.Currency, amount: number): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local success, msg = isAmount(amount)
	if not success then
		return Result.err(`bad amount: {msg}`)
	end
	local balance = SessionService:GetBalance(player, currency)
	if balance < amount then
		return Result.err(`not enough {ProductDefinition.getCurrencyName(currency)}`)
	end
	return SessionService:SetBalance(player, currency, balance - amount)
end

-- draws an artifact of the rarity the player doesn't own yet + answers with its definition id. the player owns it
-- by the time their client hears of it, the unlock cut-scene it plays is only for show
function EconomyService:GrantArtifact(player: Player, rarity: PseudoEnum.Rarity): Result<string, string>
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	local ownedIds = sessionOpt.Value.ArtifactIds
	local drawnIds: { string } = {}
	for _, itemDef in ItemAppearanceDefinition.list(ARTIFACT_GROUP, ARTIFACT_CATEGORY) do
		if
			itemDef.Rarity == rarity
			and not table.find(UNDRAWN_ARTIFACT_IDS, itemDef.Id)
			and not table.find(ownedIds, itemDef.Id)
		then
			table.insert(drawnIds, itemDef.Id)
		end
	end
	if #drawnIds == 0 then
		local rarityName = rarity == PseudoEnum.Rarity.VeryCommon and "Very Common" or rarity
		return Result.err(`every {rarityName} artifact is already owned`)
	end
	local artifactId = drawnIds[self._Random:NextInteger(1, #drawnIds)]
	local artifactIds = table.clone(ownedIds)
	table.insert(artifactIds, artifactId)
	local artifactIdsRes = SessionService:SetArtifactIds(player, artifactIds)
	if artifactIdsRes.IsErr then
		return artifactIdsRes
	end
	NetworkService:Fire(RemoteDefinition.ArtifactGranted, player, artifactId)
	return Result.ok(artifactId)
end

return ServiceLocker(function(): EconomyService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Random = Random.new(),
		_DailyRewardTimes = {},
		_DailyRewardThreads = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, EconomyService)

	NetworkService:Handle(
		RemoteDefinition.PurchaseProduct,
		function(player: Player, productId: string): Result<true, string>
			return purchaseProduct(self, player, productId)
		end
	)
	NetworkService:Handle(
		RemoteDefinition.PurchaseFurniture,
		function(player: Player, furnitureId: string): Result<true, string>
			return purchaseFurniture(self, player, furnitureId)
		end
	)
	NetworkService:Handle(
		RemoteDefinition.PurchaseTheme,
		function(player: Player, themeId: string): Result<true, string>
			return purchaseTheme(self, player, themeId)
		end
	)

	local addedConnection = SessionService.Added:Connect(function(player: Player)
		add(self, player)
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		remove(self, player)
	end)
	table.insert(self._CleanUpCallbacks, function()
		addedConnection:Disconnect()
		removingConnection:Disconnect()
		for player in self._DailyRewardThreads do
			remove(self, player)
		end
	end)
	for _, player in Players:GetPlayers() do
		if SessionService:Get(player).IsSome then
			add(self, player)
		end
	end

	return self
end, function(self: EconomyService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
