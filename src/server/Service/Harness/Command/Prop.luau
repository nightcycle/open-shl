--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Argument = require("@game/ServerScriptService/Server/Service/Harness/Argument")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local PropDefinition = require("@game/ReplicatedStorage/Shared/Definition/Prop")
local PropService = require("@game/ServerScriptService/Server/Service/Prop")
-- Types
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
local PROP_ID =
	Harness.newArgument("PropId", "string", Type.string, "the id of a prop, prop.get lists the ones of the game")
-- Variables
-- References
-- Private Functions
local function listIds(): { string }
	local ids: { string } = {}
	for _, definition in PropDefinition.list() do
		table.insert(ids, definition.Id)
	end
	return ids
end
-- Class
local Module = {}

Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"prop.get",
			"the props of the game, which of them the avatar of a player carries + which one the server counts as in its hand",
			{ Argument.Player },
			function(args: { [string]: any }): Result<any, string>
				assert(PropService.IsInitialized, `the prop service isn't initialized`)
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				local player = playerRes.Value
				local carried: { string } = {}
				for _, id in listIds() do
					if PropService:GetIfCarried(player, id) then
						table.insert(carried, id)
					end
				end
				return Result.ok({
					Ids = listIds(),
					Carried = carried,
					HeldId = PropService:GetHeldId(player),
				})
			end
		),
		Harness.newCommand(
			"prop.give",
			"hands the avatar of a player a prop through the prop service, the way a pad does",
			{ Argument.Player, PROP_ID },
			function(args: { [string]: any }): Result<any, string>
				assert(PropService.IsInitialized, `the prop service isn't initialized`)
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				if not PropService:Grant(playerRes.Value, args.PropId) then
					return Result.err(
						`"{args.PropId}" wasn't handed out: it's no prop of the game, the avatar is down or carries it already`
					)
				end
				return Result.ok(true)
			end
		),
		Harness.newCommand(
			"prop.take",
			"takes a prop off the avatar of a player through the prop service",
			{ Argument.Player, PROP_ID },
			function(args: { [string]: any }): Result<any, string>
				assert(PropService.IsInitialized, `the prop service isn't initialized`)
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				if not PropService:Take(playerRes.Value, args.PropId) then
					return Result.err(`the avatar carries no "{args.PropId}"`)
				end
				return Result.ok(true)
			end
		),
	}
end

return Module
