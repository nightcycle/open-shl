--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Remote = RemoteDefinition.Remote
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

function Util.find(name: string): Remote?
	for _, remote in RemoteDefinition.list() do
		if remote.Name == name then
			return remote
		end
	end
	return nil
end

-- has a function of the game answered as if the player had invoked it: what runs is what the network service keeps
-- for the remote, so the call is counted against the rate limit of the player, held to the validator of the remote +
-- answered by the handler of whichever service took it. most of what a player does to the server has no other way in.
-- yields the way the handler does
function Util.invoke(player: Player, remote: Remote, value: unknown): Result<any, string>
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	if remote.Kind ~= "Function" or remote.Direction ~= "ClientToServer" then
		return Result.err(`"{remote.Name}" isn't a function clients invoke: an event is fired by the client's harness`)
	end
	local handler = NetworkService._Handlers[remote.Name]
	if not handler then
		return Result.err(`nothing answers "{remote.Name}" in this game`)
	end
	local res = handler(player, value) :: any
	if type(res) ~= "table" or res.IsErr ~= false then
		return Result.err(
			if type(res) == "table" then tostring(res.Value) else `"{remote.Name}" answered with no result`
		)
	end
	return Result.ok(res.Value)
end

return Util
