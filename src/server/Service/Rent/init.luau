--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local CharacterService = require("@game/ServerScriptService/Server/Service/Character")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local RentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Rent")
local Rule = require("@self/Rule")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Character = CharacterType.Character
type PlayerSave = SaveType.PlayerSave
type RentServiceImpl = {
	__index: RentServiceImpl,
}
export type RentService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: RentServiceImpl
))
-- Constants
-- what a fee is paid in
local CURRENCY: PseudoEnum.Currency = PseudoEnum.Currency.Credits
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

local function getShortError(): string
	return `not enough {ProductDefinition.getCurrencyName(CURRENCY)}`
end

-- yields. a save, a fee + a pick in one: the character a client handed in is held to everything a save is, what it
-- has on that's neither its player's nor its slot's to keep is paid for by the visit, + it's who's played from here.
-- one write does all of it, so nobody pays for a character they didn't get + nobody plays one they didn't pay for.
-- whoever was played until now is through with what was rented for them in that same write
local function rentCharacter(self: RentService, player: Player, edited: Character): Result<Character, string>
	assert(CharacterService.IsInitialized, `the character service isn't initialized`)
	local characterRes = CharacterService:Sanitise(player, edited)
	if characterRes.IsErr then
		return characterRes
	end
	-- the filter yielded: everything from here reads the session the way it is by now
	if not self.IsInitialized or not CharacterService.IsInitialized or not SessionService.IsInitialized then
		return Result.err(`no slot holds the character`)
	end
	local character = characterRes.Value
	local sessionOpt = SessionService:Get(player)
	local prior = if sessionOpt.IsSome then getCharacter(sessionOpt.Value.Save, character.Id) else nil
	if sessionOpt.IsNone or not prior then
		return Result.err(`no slot holds the character`)
	end
	local fightError = CharacterService:RefuseFighting(player)
	if fightError then
		return Result.err(fightError)
	end
	local save = sessionOpt.Value.Save
	local section = save.SHL1
	assert(section, `a save of this game has its section`)
	-- what the slot only has on for the visit is nothing it keeps: worn on, it's due again
	local kept =
		RentDefinition.getKept(prior, if prior.Id == save.ActiveCharacterId then section.RentedItemIds else nil)
	local unlistedError = CharacterService:GetUnlistedError(character, kept)
	if unlistedError then
		return Result.err(unlistedError)
	end
	local neededIds = RentDefinition.listNeeded(character, SessionService:GetOwned(player), kept)
	local priceRes = Rule.getRentPrice(neededIds)
	if priceRes.IsErr then
		return priceRes
	end
	local price = priceRes.Value
	if save.Balances[CURRENCY] < price then
		return Result.err(getShortError())
	end
	local saveRes = SessionService:Update(player, function(t: PlayerSave): PlayerSave?
		Rule.expireSave(t)
		t.Balances[CURRENCY] -= price
		for index, other in t.Characters do
			if other.Id == character.Id then
				t.Characters[index] = character
			end
		end
		t.ActiveCharacterId = character.Id
		local own = t.SHL1
		assert(own, `a save of this game has its section`)
		own.RentedItemIds = table.clone(neededIds)
		return t
	end)
	if saveRes.IsErr then
		return saveRes
	end
	local enterRes = CharacterService:Enter(player)
	if enterRes.IsErr then
		return enterRes
	end
	local saved = getCharacter(saveRes.Value, character.Id)
	if not saved then
		return Result.err(`no slot holds the character`)
	end
	return Result.ok(saved)
end

-- whoever is played is kept in a slot, what was rented for them paid for there for good. nothing of the character is
-- a client's to say: the copy is made here, of what the save holds. kept in their own slot, nothing of them is rented
-- any more. kept in another, that slot holds a copy that's through with it + they go on renting: a second copy is paid
-- for again
local function keepCharacter(player: Player, slotId: string): Result<Character, string>
	assert(CharacterService.IsInitialized, `the character service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	local save = sessionOpt.Value.Save
	local played = getCharacter(save, save.ActiveCharacterId)
	if not played or not getCharacter(save, slotId) then
		return Result.err(`no slot holds the character`)
	end
	local fightError = CharacterService:RefuseFighting(player)
	if fightError then
		return Result.err(fightError)
	end
	local section = save.SHL1
	assert(section, `a save of this game has its section`)
	local price = Rule.getKeepPrice(section.RentedItemIds, played)
	if save.Balances[CURRENCY] < price then
		return Result.err(getShortError())
	end
	local isOwnSlot = slotId == played.Id
	local copy = FreezeUtil.delta(played, function(t: Character): Character
		t.Id = slotId
		return t
	end)
	local saveRes = SessionService:Update(player, function(t: PlayerSave): PlayerSave?
		local own = t.SHL1
		assert(own, `a save of this game has its section`)
		if isOwnSlot then
			-- they're in their own slot as they are, all there is to write is that it's theirs now
			if #own.RentedItemIds == 0 then
				return nil
			end
			own.RentedItemIds = {}
		else
			for index, other in t.Characters do
				if other.Id == slotId then
					t.Characters[index] = copy
				end
			end
		end
		t.Balances[CURRENCY] -= price
		return t
	end)
	if saveRes.IsErr then
		return saveRes
	end
	local saved = getCharacter(saveRes.Value, slotId)
	if not saved then
		return Result.err(`no slot holds the character`)
	end
	return Result.ok(saved)
end
-- Class
local RentService = {} :: RentServiceImpl
RentService.__index = RentService

-- what's behind a pass for a fee: by the visit, as a character is made, + for good, as it's kept in a slot. what was
-- rented is written down for whoever is played + nobody else: it runs out when their player leaves, makes somebody
-- new or loads another, which the session + the character service see to with the rule of this. both requests are a
-- single write to the save
return ServiceLocker(function(): RentService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(CharacterService.IsInitialized, `the character service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, RentService)

	NetworkService:Handle(
		RemoteDefinition.RentCharacter,
		function(player: Player, character: Character): Result<Character, string>
			return rentCharacter(self, player, character)
		end
	)
	NetworkService:Handle(
		RemoteDefinition.KeepCharacter,
		function(player: Player, slotId: string): Result<Character, string>
			return keepCharacter(player, slotId)
		end
	)

	return self
end, function(self: RentService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
