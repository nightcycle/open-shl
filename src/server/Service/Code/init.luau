--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local CodeDefinition = require("@game/ServerScriptService/Server/Definition/Code")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local PayoutUtil = require("@self/Payout")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local SaveType = require("@game/ServerScriptService/Server/Type/Save")
type Result<V, E> = TypeUnionLib.Result<V, E>
type PlayerSave = SaveType.PlayerSave
type CodeServiceImpl = {
	__index: CodeServiceImpl,
	Redeem: (self: CodeService, player: Player, text: string) -> Result<number, string>,
}
export type CodeService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: CodeServiceImpl
))
-- Constants
-- every text below ends up in front of a player as it is. they're new words: the old place said nothing, right or
-- wrong
local UNKNOWN_TEXT = `That code doesn't exist`
local USED_TEXT = `You already used that code`
local RETRY_TEXT = `Try again in a moment`
-- Variables
-- References
-- Private Functions
-- Class
local CodeService = {} :: CodeServiceImpl
CodeService.__index = CodeService

-- what was paid, or the line that says why nothing was. the money + the mark that it was paid go into the save in
-- one write, which can't yield: two asks that are out at once can't both be paid
function CodeService:Redeem(player: Player, text: string): Result<number, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local sessionOpt = SessionService:Get(player)
	if sessionOpt.IsNone then
		return Result.err(RETRY_TEXT)
	end
	local definition = CodeDefinition.find(text)
	if not definition then
		return Result.err(UNKNOWN_TEXT)
	end
	local isPaid = PayoutUtil.getIfPaid(sessionOpt.Value.Save, definition)
	if isPaid == nil then
		warn(`code err: the save of {player.Name} keeps no codes`)
		return Result.err(RETRY_TEXT)
	elseif isPaid then
		return Result.err(USED_TEXT)
	end
	local saveRes = SessionService:Update(player, function(save: PlayerSave): PlayerSave?
		return if PayoutUtil.pay(save, definition) then save else nil
	end)
	if saveRes.IsErr then
		warn(`code err: "{definition.Id}" of {player.Name}: {saveRes.Value}`)
		return Result.err(RETRY_TEXT)
	end
	return Result.ok(definition.Amount)
end

-- the words that pay out once for whoever types one. the old place had its client look the word up, check if it was
-- used + pay itself through a remote that took any amount: here a client sends what was typed + nothing else. what
-- comes of it reaches it the way every gain does
return ServiceLocker(function(): CodeService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, CodeService)

	NetworkService:Handle(RemoteDefinition.RedeemCode, function(player: Player, text: string): Result<number, string>
		return self:Redeem(player, text)
	end)

	return self
end, function(self: CodeService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
