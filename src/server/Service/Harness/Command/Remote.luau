--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Argument = require("@game/ServerScriptService/Server/Service/Harness/Argument")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local Request = require("@game/ServerScriptService/Server/Service/Harness/Request")
-- Types
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
local NAME = Harness.newArgument("Name", "string", Type.string, "the name of a remote, remote.list has them")
local VALUE = Harness.newArgument(
	"Value",
	"any",
	Type.any,
	"the one value the remote carries, left out for one that carries none"
)
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"remote.list",
			"every remote of the code, + whether a service of this game answers it",
			{},
			function(): Result<any, string>
				assert(NetworkService.IsInitialized, `the network service isn't initialized`)
				local out: { any } = {}
				for _, remote in RemoteDefinition.list() do
					table.insert(out, {
						Name = remote.Name,
						Kind = remote.Kind,
						Direction = remote.Direction,
						IsTaken = if remote.Direction == "ServerToClient"
							then nil
							elseif remote.Kind == "Function" then NetworkService._Handlers[remote.Name] ~= nil
							else NetworkService._IsListened[remote.Name] == true,
					})
				end
				return Result.ok(out)
			end
		),
		Harness.newCommand(
			"remote.invoke",
			"has a function of the game answered as if a player had invoked it: its rate limit, its validator, its handler",
			{ Argument.Player, NAME, Harness.optional(VALUE) },
			function(args: { [string]: any }): Result<any, string>
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				local remote = Request.find(args.Name)
				if not remote then
					return Result.err(`no remote "{args.Name}"`)
				end
				return Request.invoke(playerRes.Value, remote, args.Value)
			end
		),
	}
end

return Module
