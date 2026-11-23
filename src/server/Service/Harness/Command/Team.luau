--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Argument = require("@game/ServerScriptService/Server/Service/Harness/Argument")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local TeamService = require("@game/ServerScriptService/Server/Service/Team")
-- Types
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
local TEAM_ID = Harness.newArgument("TeamId", "string", CombatType.TeamId, "Heroes or Villains")
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"team.get",
			"the side the team service has a player on, nil in a place where nobody fights",
			{ Argument.Player },
			function(args: { [string]: any }): Result<any, string>
				assert(TeamService.IsInitialized, `the team service isn't initialized`)
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				return Result.ok({
					TeamId = TeamService:GetTeamId(playerRes.Value),
				})
			end
		),
		Harness.newCommand(
			"team.set",
			"puts a player on a side the way the team change does: balance may refuse it, + the avatar that's out goes down",
			{ Argument.Player, TEAM_ID },
			function(args: { [string]: any }): Result<any, string>
				assert(TeamService.IsInitialized, `the team service isn't initialized`)
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				local player = playerRes.Value
				-- the service only knows how to go to the other side, so whoever is there already stays as they are
				if TeamService:GetTeamId(player) == args.TeamId then
					return Result.ok({
						TeamId = args.TeamId,
						IsChanged = false,
					})
				end
				local changeRes = TeamService:ChangeTeam(player)
				if changeRes.IsErr then
					return changeRes
				end
				return Result.ok({
					TeamId = changeRes.Value,
					IsChanged = true,
				})
			end
		),
	}
end

return Module
