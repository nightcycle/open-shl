--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Burn = require("@game/ServerScriptService/Server/VFX/Library/Burn")
local Cover = require("@game/ServerScriptService/Server/VFX/Library/Cover")
local ForceShield = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/ForceShield")
local Freeze = require("@game/ServerScriptService/Server/VFX/Library/Freeze")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local VFXService = require("@game/ServerScriptService/Server/Service/VFX")
-- Types
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
local BODY = Harness.optional(
	Harness.newArgument(
		"Body",
		"string",
		Type.string,
		"who carries it: the name of a player or of a puppet, the avatar of whoever is alone on the server when left out"
	)
)
local FROM = Harness.optional(
	Harness.newArgument(
		"From",
		"string",
		Type.string,
		"who does it: the name of a player or of a puppet, the avatar of whoever is alone on the server when left out"
	)
)
local TO = Harness.newArgument("To", "string", Type.string, "who it's done to: the name of a player or of a puppet")
local COVER_DURATION = Harness.optional(
	Harness.newArgument("Duration", "number", Type.numberPositive, "seconds the tool is out for, 5 when left out")
)
local FREEZE_DURATION = Harness.optional(
	Harness.newArgument("Duration", "number", Type.numberPositive, "seconds they're held, 5 when left out")
)
local IS_BLOCKED = Harness.optional(
	Harness.newArgument(
		"IsBlocked",
		"boolean",
		Type.boolean,
		"true for the block of ice around them: it's in the way for 2 seconds past the hold"
	)
)
local AMOUNT = Harness.newArgument(
	"Amount",
	"number",
	Type.numberMin(0),
	"what every tick takes off before the rule of the game scales it"
)
local COUNT = Harness.optional(
	Harness.newArgument(
		"Count",
		"number",
		Type.intersection(Type.integer, Type.numberPositive),
		"how many ticks, 10 when left out"
	)
)
local INTERVAL = Harness.optional(
	Harness.newArgument("Interval", "number", Type.numberPositive, "seconds between two ticks, 0.5 when left out")
)
local FLAME_DURATION = Harness.optional(
	Harness.newArgument("FlameDuration", "number", Type.numberMin(0), "seconds they're seen on fire, 5 when left out")
)
local DEFAULT_COVER_DURATION = 5
local DEFAULT_FREEZE_DURATION = 5
local DEFAULT_COUNT = 10
local DEFAULT_INTERVAL = 0.5
local DEFAULT_FLAME_DURATION = 5
-- the block legacy's freeze ray shut its victim in, until the power that owns these numbers is in
local BLOCK: Cover.Properties = table.freeze({
	Size = Vector3.new(5, 7, 5),
	Offset = CFrame.new(0, 1, 0),
	Color = Color3.fromRGB(152, 194, 219),
	Material = Enum.Material.Ice,
	Transparency = 0.3,
	GrowDuration = 1,
})
local BLOCK_LINGER = 2
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- what a power sets off on a body besides the hit itself, for the ones no body in a test can hold: a puppet has no
-- tools, + the powers that freeze + burn come after the effects they fire
Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"status.cover",
			"raises Force Field's shield ahead of a body for a while, the way the power does while its tool is out. a ray ends at it + a swing from its far side lands nothing",
			{ BODY, COVER_DURATION },
			function(args: { [string]: any }): Result<any, string>
				assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
				local bodyRes = context.Bodies:Get(args.Body)
				if bodyRes.IsErr then
					return bodyRes
				end
				local body = bodyRes.Value
				local config = ForceShield.Config
				local duration = args.Duration or DEFAULT_COVER_DURATION
				local handle = VFXService:NewScope(body.Player, body.Character).start(Cover, {
					Size = config.Size,
					Offset = config.Offset,
					Color = config.Color,
					Material = Enum.Material.Neon,
					Transparency = config.Transparency,
					FadeDuration = config.FadeDuration,
					Delay = config.Delay,
					Linger = config.Linger,
				})
				task.delay(duration, handle.Stop)
				return Result.ok({
					Body = body.Name,
					Duration = duration,
					Delay = config.Delay,
				})
			end
		),
		Harness.newCommand(
			"status.freeze",
			"one body freezes another through the Freeze effect, as far as the rule of the game lets them: answers if it took + whether they're frozen",
			{ FROM, TO, FREEZE_DURATION, IS_BLOCKED },
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
				local duration = args.Duration or DEFAULT_FREEZE_DURATION
				local isFrozen = VFXService:NewScope(from.Player, from.Character).fire(Freeze, {
					Target = to.Character,
					Duration = duration,
					Block = if args.IsBlocked then BLOCK else nil,
					BlockDuration = if args.IsBlocked then duration + BLOCK_LINGER else nil,
				})
				return Result.ok({
					IsLanded = isFrozen,
					IsFrozen = AttributeDefinition.get(to.Character, AttributeDefinition.IsFrozen),
					Duration = duration,
				})
			end
		),
		Harness.newCommand(
			"status.burn",
			"one body sets another alight through the Burn effect, as far as the rule of the game lets them: answers if it caught + their health after the first tick",
			{ FROM, TO, AMOUNT, COUNT, INTERVAL, FLAME_DURATION },
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
				local isLanded = VFXService:NewScope(from.Player, from.Character).fire(Burn, {
					Target = to.Character,
					Amount = args.Amount,
					Count = args.Count or DEFAULT_COUNT,
					Interval = args.Interval or DEFAULT_INTERVAL,
					FlameDuration = args.FlameDuration or DEFAULT_FLAME_DURATION,
				})
				local health = AttributeDefinition.get(to.Character, AttributeDefinition.Health)
				return Result.ok({
					IsLanded = isLanded,
					Taken = priorHealth - health,
					Health = health,
				})
			end
		),
	}
end

return Module
