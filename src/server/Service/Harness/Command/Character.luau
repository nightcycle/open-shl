--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
local Argument = require("@game/ServerScriptService/Server/Service/Harness/Argument")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local Request = require("@game/ServerScriptService/Server/Service/Harness/Request")
-- Types
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
local CHARACTER_ID =
	Harness.newArgument("CharacterId", "string", Type.string, "the id of a slot, session.get lists them")
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the character service has no method for either: both are what it answers a remote with, so that's what's asked
Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"character.select",
			"has a player play another slot, the way the character select asks for it",
			{ Argument.Player, CHARACTER_ID },
			function(args: { [string]: any }): Result<any, string>
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				return Request.invoke(playerRes.Value, RemoteDefinition.SelectCharacter, args.CharacterId)
			end
		),
		Harness.newCommand(
			"character.swap",
			"has a player swap to their other identity, the way the swap button asks for it. answers with who they'll be",
			{ Argument.Player },
			function(args: { [string]: any }): Result<any, string>
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				return Request.invoke(playerRes.Value, RemoteDefinition.SwapIdentity, nil)
			end
		),
	}
end

return Module
