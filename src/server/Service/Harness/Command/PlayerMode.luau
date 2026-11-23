--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Argument = require("@game/ServerScriptService/Server/Service/Harness/Argument")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local PlayerModeService = require("@game/ServerScriptService/Server/Service/PlayerMode")
-- Types
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
local IS_PEACEFUL =
	Harness.newArgument("IsPeaceful", "boolean", Type.boolean, "true for RP: the player sits fights out. false for PVP")
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"playermode.get",
			"whether a player sits fights out, as their save has it",
			{ Argument.Player },
			function(args: { [string]: any }): Result<any, string>
				assert(PlayerModeService.IsInitialized, `the player mode service isn't initialized`)
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				return Result.ok({
					IsPeaceful = PlayerModeService:GetIfPeaceful(playerRes.Value),
				})
			end
		),
		Harness.newCommand(
			"playermode.set",
			"has a player sit fights out or fight, through the service their own pick goes to",
			{ Argument.Player, IS_PEACEFUL },
			function(args: { [string]: any }): Result<any, string>
				assert(PlayerModeService.IsInitialized, `the player mode service isn't initialized`)
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				return PlayerModeService:SetPeaceful(playerRes.Value, args.IsPeaceful)
			end
		),
	}
end

return Module
