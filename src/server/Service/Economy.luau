--!strict
-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type Result<V, E> = TypeUnionLib.Result<V, E>
type EntitlementKey = EconomyType.EntitlementKey
type ProductDefinition = EconomyType.ProductDefinition
type Receipt = EconomyType.Receipt
type PlayerSave = SaveType.PlayerSave
-- what a game sells for one of its currencies + a player owns once
export type Purchasable = {
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
	Purchase: (
		self: EconomyService,
		player: Player,
		purchasable: Purchasable,
		getOwnedIds: (save: PlayerSave) -> { string },
		ids: { string }?
	) -> Result<true, string>,
	Spend: (
		self: EconomyService,
		player: Player,
		currency: PseudoEnum.Currency,
		price: number,
		write: (save: PlayerSave) -> ()
	) -> Result<true, string>,
}
export type EconomyService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_DailyRewardThreads: { [Player]: thread },
		-- the passes of everyone with a session that the engine is being asked about because a prompt ended on paid
		-- for, one call per pass at a time
		_PurchasedPassKeys: { [Player]: { EntitlementKey } },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: EconomyServiceImpl
))
-- Constants
local DAILY_REWARD = ProductDefinition.DAILY_REWARD
-- how long after a player joined the daily reward is looked at
local DAILY_REWARD_DELAY = 20
-- the engine only hands a receipt in again until it's told the receipt is done with, so the last few are all that's
-- ever compared against
local MAX_PURCHASE_IDS = 100
-- how long a receipt is held for a save that's still on its way
local RECEIPT_SESSION_TIMEOUT = 30
-- asking if a pass is owned is a web call, it's made a few times over before a player goes a visit without theirs
local PASS_ATTEMPTS = 3
-- a pass that was only just paid for can take a while to count as owned, it's given longer than a call that failed
local PURCHASED_PASS_ATTEMPTS = 6
local PASS_RETRY_DELAY = 2
-- whether a pass of the game is sold as the asset it was before there were game passes: the engine tells of such a
-- prompt on a signal of its own, which is only listened to where there's one to hear of
local HAS_ASSET_PASSES = false
for _, definition in ProductDefinition.list() do
	if ProductDefinition.getIfGamePass(definition) and select(2, ProductDefinition.getPassPrompt(definition)) then
		HAS_ASSET_PASSES = true
	end
end
local isAmount = EconomyType.Balance
local isReceipt = EconomyType.Receipt
-- Variables
-- References
-- Private Functions
-- whoever asked only wants to know if the save took the change
local function update(player: Player, fn: (save: PlayerSave) -> PlayerSave?): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local saveRes = SessionService:Update(player, fn)
	if saveRes.IsErr then
		return saveRes
	end
	return Result.ok(true :: any) :: TypeUnionLib.Ok<true>
end

-- a pass is never saved, the session holds it for the visit + everything that reads an entitlement reads it there
local function addPassEntitlement(player: Player, key: EntitlementKey)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone or table.find(sessionOpt.Value.PassEntitlements, key) then
		return
	end
	local out = table.clone(sessionOpt.Value.PassEntitlements)
	table.insert(out, key)
	local setRes = SessionService:SetPassEntitlements(player, out)
	if setRes.IsErr then
		warn(`pass err: "{key}" of {player.Name}: {setRes.Value}`)
	end
end

-- they can be gone by the time an answer is in, so can the service
local function getIfGone(self: EconomyService, player: Player): boolean
	return not self.IsInitialized or self._PurchasedPassKeys[player] == nil
end

-- yields. the engine is asked every way it knows a pass by: as the game pass it is, + one from before there were
-- game passes as the asset it was sold as, under every id it ever had. owning it one way is owning it, a call that
-- failed only counts where none of them said yes
local function getIfPassOwnedNow(player: Player, definition: ProductDefinition): Result<boolean, string>
	local errors: { string } = {}
	local function ask(fn: () -> boolean): boolean
		local success, value = pcall(fn)
		if not success then
			table.insert(errors, tostring(value))
		end
		return success and value == true
	end
	local passId: number? = if definition.IsAsset then definition.PassId else definition.LegacyId
	local assetIds: { number } = if definition.IsAsset then { definition.LegacyId } else {}
	if definition.IsAsset and definition.OtherLegacyIds then
		for _, assetId in definition.OtherLegacyIds do
			table.insert(assetIds, assetId)
		end
	end
	if
		passId
		and ask(function(): boolean
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, passId)
		end)
	then
		return Result.ok(true)
	end
	for _, assetId in assetIds do
		if ask(function(): boolean
			return MarketplaceService:PlayerOwnsAssetAsync(player, assetId)
		end) then
			return Result.ok(true)
		end
	end
	return if errors[1] then Result.err(errors[1]) else Result.ok(false)
end

-- yields. for a pass that was only just paid for a no is asked about again the way a call that failed is
local function getIfPassOwned(
	self: EconomyService,
	player: Player,
	definition: ProductDefinition,
	isPurchased: boolean
): Result<boolean, string>
	local attempts = if isPurchased then PURCHASED_PASS_ATTEMPTS else PASS_ATTEMPTS
	local res: Result<boolean, string> = Result.err(`it wasn't asked for`)
	for attempt = 1, attempts do
		res = getIfPassOwnedNow(player, definition)
		if (res.IsOk and (res.Value or not isPurchased)) or attempt == attempts then
			break
		end
		task.wait(PASS_RETRY_DELAY)
		if getIfGone(self, player) then
			break
		end
	end
	return res
end

-- yields
local function checkPasses(self: EconomyService, player: Player)
	for _, definition in ProductDefinition.list() do
		local grant = definition.Grant
		if grant.Type ~= "Entitlement" then
			continue
		end
		local ownedRes = getIfPassOwned(self, player, definition, false)
		if getIfGone(self, player) then
			return
		end
		if ownedRes.IsErr then
			warn(`pass err: "{definition.Name}" of {player.Name}: {ownedRes.Value}`)
		elseif ownedRes.Value then
			addPassEntitlement(player, grant.Key)
		end
	end
end

-- yields. a prompt is ended by the client of whoever it was for, so that it was paid for is only a reason to ask the
-- engine. a pass it doesn't own up to in time is theirs with their next visit
local function checkPurchasedPass(
	self: EconomyService,
	player: Player,
	definition: ProductDefinition,
	key: EntitlementKey
)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local purchasedKeys = self._PurchasedPassKeys[player]
	local sessionOpt = SessionService:Get(player)
	if
		not purchasedKeys
		or sessionOpt.IsNone
		or table.find(purchasedKeys, key)
		or table.find(sessionOpt.Value.PassEntitlements, key)
	then
		return
	end
	table.insert(purchasedKeys, key)
	local ownedRes = getIfPassOwned(self, player, definition, true)
	if getIfGone(self, player) then
		return
	end
	table.remove(purchasedKeys, table.find(purchasedKeys, key))
	if ownedRes.IsErr then
		warn(`pass err: "{definition.Name}" of {player.Name}: {ownedRes.Value}`)
	elseif ownedRes.Value then
		addPassEntitlement(player, key)
	else
		warn(
			`pass err: "{definition.Name}" of {player.Name}: a prompt ended on paid for, the engine says it isn't owned`
		)
	end
end

-- what a product hands over + the receipt it was paid with go into the save in one write, a save never holds one
-- without the other. a product that was handed over for free has no receipt
local function grantProduct(player: Player, definition: ProductDefinition, purchaseId: string?): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	local grant = definition.Grant
	if grant.Type == "Entitlement" and table.find(SessionService:GetEntitlements(player), grant.Key) then
		return Result.err(`"{definition.Name}" is already owned`)
	end
	return update(player, function(save: PlayerSave): PlayerSave?
		if grant.Type == "Currency" then
			save.Balances[grant.Currency] += grant.Amount
		elseif grant.Type == "Entitlement" then
			table.insert(save.Entitlements, grant.Key)
		end
		if purchaseId then
			table.insert(save.PurchaseIds, purchaseId)
			while #save.PurchaseIds > MAX_PURCHASE_IDS do
				table.remove(save.PurchaseIds, 1)
			end
		end
		return save
	end)
end

-- yields. answers the engine if a receipt is done with. one that isn't is handed in again later + paid back if it
-- never is, so it's only done with once the save holds what it paid for
local function processReceipt(self: EconomyService, value: unknown): Enum.ProductPurchaseDecision
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local success, msg = isReceipt(value)
	if not success then
		warn(`bad receipt: {msg}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local receipt = value :: Receipt
	local definitionRes = ProductDefinition.getFromLegacyId(receipt.ProductId, false)
	if definitionRes.IsErr then
		warn(`receipt err: {definitionRes.Value}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- the engine hands in what a player still has open as they join, their save takes longer than that to get here.
	-- turned down right away the receipt would only come back with their next visit, to lose the same race again
	local startTime = os.clock()
	while
		self.IsInitialized
		and SessionService.IsInitialized
		and SessionService:Get(player).IsNone
		and player.Parent ~= nil
		and os.clock() - startTime < RECEIPT_SESSION_TIMEOUT
	do
		task.wait()
	end
	if not self.IsInitialized or not SessionService.IsInitialized then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- a save that isn't loaded can't take anything
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- the engine didn't hear the answer the first time, the product isn't handed over twice for it
	if table.find(sessionOpt.Value.Save.PurchaseIds, receipt.PurchaseId) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	local grantRes = grantProduct(player, definitionRes.Value, receipt.PurchaseId)
	if grantRes.IsErr then
		warn(`receipt err: "{definitionRes.Value.Name}" of {player.Name}: {grantRes.Value}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- a few gems once per rolling day, counted from the last time they were handed out on whatever server that was
local function grantDailyReward(player: Player)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	local now = os.time()
	-- a game without one hands nothing out, + keeps no time of the last one
	local reward = DAILY_REWARD
	if reward == nil or sessionOpt.IsNone or now - (sessionOpt.Value.Save.LastDailyRewardAt or 0) < reward.INTERVAL then
		return
	end
	local grantRes = update(player, function(save: PlayerSave): PlayerSave?
		save.Balances[reward.CURRENCY] += reward.AMOUNT
		save.LastDailyRewardAt = now
		return save
	end)
	if grantRes.IsErr then
		warn(`daily reward err: {grantRes.Value}`)
		return
	end
	NetworkService:Fire(RemoteDefinition.DailyRewardGranted, player, {
		Currency = reward.CURRENCY,
		Amount = reward.AMOUNT,
	})
end

local function add(self: EconomyService, player: Player)
	if self._PurchasedPassKeys[player] then
		return
	end
	self._PurchasedPassKeys[player] = {}
	task.spawn(checkPasses, self, player)
	if DAILY_REWARD ~= nil then
		self._DailyRewardThreads[player] = task.delay(DAILY_REWARD_DELAY, function()
			self._DailyRewardThreads[player] = nil
			grantDailyReward(player)
		end)
	end
end

local function remove(self: EconomyService, player: Player)
	local thread = self._DailyRewardThreads[player]
	if thread and coroutine.status(thread) == "suspended" then
		task.cancel(thread)
	end
	self._DailyRewardThreads[player] = nil
	self._PurchasedPassKeys[player] = nil
end
-- Class
local EconomyService = {} :: EconomyServiceImpl
EconomyService.__index = EconomyService

function EconomyService:Grant(player: Player, currency: PseudoEnum.Currency, amount: number): Result<true, string>
	local success, msg = isAmount(amount)
	if not success then
		return Result.err(`bad amount: {msg}`)
	end
	return update(player, function(save: PlayerSave): PlayerSave?
		save.Balances[currency] += amount
		return save
	end)
end

-- the price is taken + the piece is owned in one write, a save never holds one without the other. where a save keeps
-- what's owned is whoever sells it to say. ids are what it hands over where that's more than itself: all of them
-- for the one price, + it's only owned already once every one of them is
function EconomyService:Purchase(
	player: Player,
	purchasable: Purchasable,
	getOwnedIds: (save: PlayerSave) -> { string },
	ids: { string }?
): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	local save = sessionOpt.Value.Save
	local handedIds: { string } = ids or { purchasable.Id }
	local ownedIds = getOwnedIds(save)
	local isOwned = true
	for _, id in handedIds do
		isOwned = isOwned and table.find(ownedIds, id) ~= nil
	end
	if isOwned then
		return Result.err(`"{purchasable.Name}" is already owned`)
	end
	if save.Balances[purchasable.Currency] < purchasable.Price then
		return Result.err(`not enough {ProductDefinition.getCurrencyName(purchasable.Currency)}`)
	end
	return update(player, function(t: PlayerSave): PlayerSave?
		t.Balances[purchasable.Currency] -= purchasable.Price
		local list = getOwnedIds(t)
		for _, id in handedIds do
			if not table.find(list, id) then
				table.insert(list, id)
			end
		end
		return t
	end)
end

-- for what's sold that isn't an id on a list of the save: the price is taken + what it bought is written in one
-- write, a save never holds one without the other. whether it may be bought at all is whoever sells it's to say
function EconomyService:Spend(
	player: Player,
	currency: PseudoEnum.Currency,
	price: number,
	write: (save: PlayerSave) -> ()
): Result<true, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local success, msg = isAmount(price)
	if not success then
		return Result.err(`bad price: {msg}`)
	end
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	if sessionOpt.Value.Save.Balances[currency] < price then
		return Result.err(`not enough {ProductDefinition.getCurrencyName(currency)}`)
	end
	return update(player, function(save: PlayerSave): PlayerSave?
		save.Balances[currency] -= price
		write(save)
		return save
	end)
end

return ServiceLocker(function(): EconomyService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_DailyRewardThreads = {},
		_PurchasedPassKeys = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, EconomyService)

	NetworkService:Handle(
		RemoteDefinition.PurchaseProduct,
		function(player: Player, productId: string): Result<true, string>
			-- the product is handed over for free, that's only for where nobody plays for real
			if not RunService:IsStudio() then
				return Result.err(`products are only free in studio`)
			end
			local definitionRes = ProductDefinition.get(productId)
			if definitionRes.IsErr then
				return definitionRes
			end
			return grantProduct(player, definitionRes.Value, nil)
		end
	)

	-- the engine holds on to the callback for as long as the server runs, the service can be gone when it's called
	MarketplaceService.ProcessReceipt = function(receipt: unknown): Enum.ProductPurchaseDecision
		if not self.IsInitialized or not SessionService.IsInitialized then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		return processReceipt(self, receipt)
	end
	-- a prompt of a pass ended, as the game pass or as the asset it was prompted as
	local function finishPassPrompt(player: Player, id: number, isAsset: boolean, isPurchased: boolean)
		local definitionRes = ProductDefinition.getFromPassPrompt(id, isAsset)
		if not isPurchased or definitionRes.IsErr then
			return
		end
		local grant = definitionRes.Value.Grant
		if grant.Type == "Entitlement" then
			checkPurchasedPass(self, player, definitionRes.Value, grant.Key)
		end
	end
	table.insert(
		self._Connections,
		MarketplaceService.PromptGamePassPurchaseFinished:Connect(
			function(player: Player, passId: number, isPurchased: boolean)
				finishPassPrompt(player, passId, false, isPurchased)
			end
		)
	)
	if HAS_ASSET_PASSES then
		table.insert(
			self._Connections,
			MarketplaceService.PromptPurchaseFinished:Connect(
				function(player: Player, assetId: number, isPurchased: boolean)
					finishPassPrompt(player, assetId, true, isPurchased)
				end
			)
		)
	end

	local addedConnection = SessionService.Added:Connect(function(player: Player)
		add(self, player)
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		remove(self, player)
	end)
	table.insert(self._CleanUpCallbacks, function()
		addedConnection:Disconnect()
		removingConnection:Disconnect()
		for player in self._PurchasedPassKeys do
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
