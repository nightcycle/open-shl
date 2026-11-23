--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Argument = require("@game/ServerScriptService/Server/Service/Harness/Argument")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Character = CharacterType.Character
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
local IS_WHOLE = Harness.newArgument(
	"IsWhole",
	"boolean",
	Type.boolean,
	"true for the save as it is, every appearance + layout included: it's long"
)
-- Variables
-- References
-- Private Functions
-- who a slot holds without what they wear
local function summarize(character: Character): { [string]: any }
	local powers: { string } = {}
	for _, power in character.Powers do
		table.insert(powers, power.Id)
	end
	local identities: { [string]: any } = {}
	for identityKey, identity in character.Identities :: { [string]: any } do
		identities[identityKey] = {
			Name = identity.Profile.Name,
			Alignment = identity.Profile.Alignment,
			ItemCount = #identity.Appearance.Items,
		}
	end
	return {
		Id = character.Id,
		Powers = powers,
		Identities = identities,
	}
end
-- Class
local Module = {}

Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"session.get",
			"what the server holds of a player: who they play, every slot, the balances + what only this game saves",
			{ Argument.Player, Harness.optional(IS_WHOLE) },
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
				local session = sessionOpt.Value
				local save = session.Save
				local characters: { any } = {}
				for _, character in save.Characters do
					table.insert(characters, summarize(character))
				end
				return Result.ok({
					Player = player.Name,
					ActiveCharacterId = save.ActiveCharacterId,
					ActiveIdentityKey = session.ActiveIdentityKey,
					IsInMenu = session.IsInMenu,
					Characters = characters, -- in slot order
					Balances = save.Balances,
					Entitlements = SessionService:GetEntitlements(player), -- what's saved + the passes of this visit
					Quest = session.Quest,
					-- the section a save of this game has, nil in the game whose fields sit on the save itself
					Section = save.SHL1 or save.SHL3,
					Version = save.Version,
					Game = save.Game,
					Save = if args.IsWhole then save else nil,
				})
			end
		),
	}
end

return Module
