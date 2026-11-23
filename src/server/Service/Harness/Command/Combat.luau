--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Attack = require("@game/ServerScriptService/Server/VFX/Library/Attack")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local VFXService = require("@game/ServerScriptService/Server/Service/VFX")
-- Types
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
local FROM = Harness.optional(
	Harness.newArgument(
		"From",
		"string",
		Type.string,
		"who hits: the name of a player or of a puppet, the avatar of whoever is alone on the server when left out"
	)
)
local TO = Harness.newArgument("To", "string", Type.string, "who's hit: the name of a player or of a puppet")
local AMOUNT = Harness.newArgument(
	"Amount",
	"number",
	Type.numberMin(0),
	"the damage of the power before the rule of the game scales it"
)
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"combat.hit",
			"one body hits another through the Attack effect, the way a power does once the server agreed it reached",
			{ FROM, TO, AMOUNT },
			function(args: { [string]: any }): Result<any, string>
				assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
				local fromRes = context.Bodies:Get(args.From)
				if fromRes.IsErr then
					return fromRes
				end
				local toRes = context.Bodies:Get(args.To)
				if toRes.IsErr then
					return toRes
				end
				local from, to = fromRes.Value, toRes.Value
				local priorHealth = AttributeDefinition.get(to.Character, AttributeDefinition.Health)
				-- what the rule says of the two before anything is taken: a hit that doesn't land is one of these two
				local isHostile = CombatDefinition.getIfHostile(from.Character, to.Character)
				local damage = CombatDefinition.getDamage(from.Character, to.Character, args.Amount)
				-- the scope a power of the attacker runs its effects in: a puppet has no player to pay or to name
				local scope = VFXService:NewScope(from.Player, from.Character)
				local isLanded = scope.fire(Attack, {
					Target = to.Character,
					Amount = args.Amount,
				})
				local health = AttributeDefinition.get(to.Character, AttributeDefinition.Health)
				return Result.ok({
					IsLanded = isLanded,
					IsHostile = isHostile,
					Damage = damage,
					Taken = priorHealth - health,
					Health = health,
					IsDead = AttributeDefinition.get(to.Character, AttributeDefinition.IsDead),
					DownedBy = AttributeDefinition.get(to.Character, AttributeDefinition.DownedBy),
					FightingUntil = {
						From = AttributeDefinition.get(from.Character, AttributeDefinition.FightingUntil),
						To = AttributeDefinition.get(to.Character, AttributeDefinition.FightingUntil),
					},
					Time = CombatDefinition.getTime(),
				})
			end
		),
	}
end

return Module
