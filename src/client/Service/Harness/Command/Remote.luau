--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Remote = RemoteDefinition.Remote
-- Constants
local NAME =
	Harness.newArgument("Name", "string", Type.string, "the name of a remote, the server's remote.list has them")
local VALUE = Harness.newArgument(
	"Value",
	"any",
	Type.any,
	"the one value the remote carries, left out for one that carries none"
)
-- Variables
-- References
-- Private Functions
-- a remote this client may call, of the kind that's asked for
local function find(name: string, kind: RemoteDefinition.Kind): Result<Remote, string>
	for _, remote in RemoteDefinition.list() do
		if remote.Name == name then
			if remote.Kind ~= kind or remote.Direction ~= "ClientToServer" then
				return Result.err(`"{name}" is a {remote.Kind} that goes {remote.Direction}`)
			end
			return Result.ok(remote)
		end
	end
	return Result.err(`no remote "{name}"`)
end
-- Class
local Module = {}

-- what the client's own services + menus do to reach the server, for whatever has no command of its own yet. both go
-- through the network service of the client, so the server takes them for what they are: a call of this player
Module.list = function(): { Command }
	return {
		Harness.newCommand(
			"remote.fire",
			"fires an event of the game at the server as this player, through the client's network service",
			{ NAME, Harness.optional(VALUE) },
			function(args: { [string]: any }): Result<any, string>
				assert(NetworkService.IsInitialized, `the network service isn't initialized`)
				local remoteRes = find(args.Name, "Event")
				if remoteRes.IsErr then
					return remoteRes
				end
				local remote = remoteRes.Value
				-- the service only warns about a value the remote doesn't take, here it's said
				local isValid, problem = remote.Argument(args.Value)
				if not isValid then
					return Result.err(`"{remote.Name}" doesn't take that: {problem}`)
				end
				NetworkService:Fire(remote :: any, args.Value)
				return Result.ok(true)
			end
		),
		Harness.newCommand(
			"remote.invoke",
			"invokes a function of the game on the server as this player, through the client's network service. answers with what the server said",
			{ NAME, Harness.optional(VALUE) },
			function(args: { [string]: any }): Result<any, string>
				assert(NetworkService.IsInitialized, `the network service isn't initialized`)
				local remoteRes = find(args.Name, "Function")
				if remoteRes.IsErr then
					return remoteRes
				end
				local remote = remoteRes.Value
				local isValid, problem = remote.Argument(args.Value)
				if not isValid then
					return Result.err(`"{remote.Name}" doesn't take that: {problem}`)
				end
				return NetworkService:Invoke(remote :: any, args.Value)
			end
		),
	}
end

return Module
