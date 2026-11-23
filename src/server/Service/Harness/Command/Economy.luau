--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Argument = require("@game/ServerScriptService/Server/Service/Harness/Argument")
local EconomyService = require("@game/ServerScriptService/Server/Service/Economy")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
-- the checker has the list for one of its own literals, which is no list of strings to it
local CURRENCIES: { string } = PseudoEnum.getEnumItems("Currency") :: { any }
local CURRENCY = Harness.newArgument(
	"Currency",
	"string",
	Type.literal(table.unpack(CURRENCIES)),
	`one of {table.concat(CURRENCIES, ", ")}`
)
local AMOUNT = Harness.newArgument("Amount", "number", Type.number, "how much, whatever the economy service takes")
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"economy.grant",
			"hands a player currency through the economy service. answers with the balances it left them with",
			{ Argument.Player, CURRENCY, AMOUNT },
			function(args: { [string]: any }): Result<any, string>
				assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
				assert(SessionService.IsInitialized, `the session service isn't initialized`)
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				local player = playerRes.Value
				local grantRes = EconomyService:Grant(player, args.Currency, args.Amount)
				if grantRes.IsErr then
					return grantRes
				end
				local sessionOpt = SessionService:Get(player)
				return Result.ok(if sessionOpt.IsSome then sessionOpt.Value.Save.Balances else nil)
			end
		),
	}
end

return Module
