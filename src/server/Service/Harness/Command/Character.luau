--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Argument = require("@game/ServerScriptService/Server/Service/Harness/Argument")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local Request = require("@game/ServerScriptService/Server/Service/Harness/Request")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Character = CharacterType.Character
type Power = CharacterType.Power
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
local CHARACTER_ID =
	Harness.newArgument("CharacterId", "string", Type.string, "the id of a slot, session.get lists them")
local POWER_IDS = Harness.newArgument(
	"PowerIds",
	"table",
	Type.array(Type.string),
	'the ids of the powers the slot is saved with, in order: { "ranged_minigun", "transportation_flight" }'
)
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the character service has no method for any of these: each is what it answers a remote with, so that's what's asked
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
		Harness.newCommand(
			"character.powers",
			"has a player save a slot with other powers in it, the way the editor's Done asks for it: what the save "
				.. "holds a power to (its slot, its price, its lock) may turn it down. answers with what the slot has",
			{ Argument.Player, Harness.optional(CHARACTER_ID), POWER_IDS },
			function(args: { [string]: any }): Result<any, string>
				assert(SessionService.IsInitialized, `the session service isn't initialized`)
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				local player = playerRes.Value
				local sessionOpt = SessionService:Get(player)
				if sessionOpt.IsNone then
					return Result.err(`{player.Name} has no session yet`)
				end
				local save = sessionOpt.Value.Save
				local characterId: string = args.CharacterId or save.ActiveCharacterId
				for _, character in save.Characters do
					if character.Id == characterId then
						local powers: { Power } = {}
						for _, powerId in args.PowerIds :: { string } do
							table.insert(powers, { Id = powerId })
						end
						local edited: Character = table.clone(character)
						edited.Powers = powers
						local res = Request.invoke(player, RemoteDefinition.SaveCharacter, edited)
						if res.IsErr then
							return res
						end
						local out: { string } = {}
						for _, power in (res.Value :: Character).Powers do
							table.insert(out, power.Id)
						end
						return Result.ok({ CharacterId = characterId, Powers = out })
					end
				end
				return Result.err(`{player.Name} has no slot "{characterId}"`)
			end
		),
	}
end

return Module
