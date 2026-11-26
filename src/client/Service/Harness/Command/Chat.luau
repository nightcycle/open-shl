--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local ChatService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Chat")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
-- Constants
local IS_MUTING =
	Harness.newArgument("IsMuting", "boolean", Type.boolean, "true to read nothing of the players of the other mode")
-- Variables
-- References
-- Private Functions
local function getState(): { [string]: any }
	assert(ChatService.IsInitialized, `the chat service isn't initialized`)
	return {
		Lines = ChatService:GetLines(),
		IsMuting = ChatService:GetIfMuting(),
	}
end
-- Class
local Module = {}

Module.list = function(): { Command }
	return {
		Harness.newCommand(
			"chat.get",
			"what this client's chat service holds: the lines of the game's own log, the newest last (always none in a game that reads its chat off the engine's window), + whether this player mutes the other mode",
			{},
			function(): Result<any, string>
				return Result.ok(getState())
			end
		),
		Harness.newCommand(
			"chat.mute",
			"what the Mute button of the log does: the lines that come in after it are judged by it, the ones that are in stay",
			{ IS_MUTING },
			function(args: { [string]: any }): Result<any, string>
				assert(ChatService.IsInitialized, `the chat service isn't initialized`)
				ChatService:SetMuting(args.IsMuting)
				return Result.ok(getState())
			end
		),
	}
end

return Module
