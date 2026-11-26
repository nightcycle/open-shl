--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Argument = require("@game/ServerScriptService/Server/Service/Harness/Argument")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local VipServerService = require("@game/ServerScriptService/Server/Service/VipServer")
-- Types
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
local IS_PVP = Harness.newArgument("IsPVP", "boolean", Type.boolean, "true for PVP, false for RP")
local IS_OWNER = Harness.newArgument("IsOwner", "boolean", Type.boolean, "what the player is told of the server")
-- Variables
-- References
-- Private Functions
local function get(): { [string]: any }
	return {
		IsPVP = AttributeDefinition.get(Workspace, AttributeDefinition.IsPVP),
		IsPrivateServer = AttributeDefinition.get(Workspace, AttributeDefinition.IsPrivateServer),
	}
end
-- Class
-- no session of studio is a private server, so what its owner does is done from here
local Module = {}

Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"server.get",
			"what the server plays by + if somebody owns it",
			{},
			function(): Result<any, string>
				return Result.ok(get())
			end
		),
		Harness.newCommand(
			"server.pvp",
			"has the server take up or drop fighting, through the service the owner's button goes to",
			{ IS_PVP },
			function(args: { [string]: any }): Result<any, string>
				assert(VipServerService.IsInitialized, `the vip server service isn't initialized`)
				VipServerService:SetPVP(args.IsPVP)
				return Result.ok(get())
			end
		),
		Harness.newCommand(
			"server.owner",
			"tells a player the server is theirs or isn't, so their hud has the button or not. the server goes on "
				.. "refusing their press: it asks the engine who the owner is",
			{ Argument.Player, IS_OWNER },
			function(args: { [string]: any }): Result<any, string>
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				AttributeDefinition.set(playerRes.Value, AttributeDefinition.IsServerOwner, args.IsOwner)
				return Result.ok({
					IsServerOwner = args.IsOwner,
				})
			end
		),
	}
end

return Module
