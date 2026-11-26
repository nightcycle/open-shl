--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AlertService = require("@game/ServerScriptService/Server/Service/Alert")
local Attack = require("@game/ServerScriptService/Server/VFX/Library/Attack")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local DisasterDefinition = require("@game/ReplicatedStorage/Shared/Definition/Disaster")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local LaserGateDefinition = require("@game/ServerScriptService/Server/Definition/LaserGate")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
local TakeDownUtil = require("@game/ServerScriptService/Server/Util/TakeDown")
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
local DISASTER_ID = Harness.newArgument(
	"DisasterId",
	"string",
	Type.string,
	"the id the map marks the target with, as crime.get lists them"
)
local AMOUNT = Harness.newArgument(
	"Amount",
	"number",
	Type.numberMin(0),
	"the damage of the power: a target takes it as it is, the rule of the game scales it for an avatar alone"
)
local TEXT = Harness.newArgument("Text", "string", Type.string, "the line the strip reads")
local TO = Harness.optional(
	Harness.newArgument(
		"To",
		"string",
		Type.string,
		"the one player who's sent it, every hero of the server when left out"
	)
)
-- Variables
-- References
-- Private Functions
local function getTarget(id: string): Model?
	for _, target in MapDefinition.list(MapDefinition.DisasterTarget) do
		local idRes = MapDefinition.get(target, MapDefinition.DisasterId)
		if idRes.IsOk and idRes.Value == id then
			return target
		end
	end
	return nil
end

local function describeTarget(target: Model): { [string]: any }
	local idRes = MapDefinition.get(target, MapDefinition.DisasterId)
	local disasterRes = if idRes.IsOk then DisasterDefinition.get(idRes.Value) else nil
	return {
		DisasterId = if idRes.IsOk then idRes.Value else nil,
		Position = target:GetPivot().Position,
		Health = AttributeDefinition.get(target, AttributeDefinition.Health),
		MaxHealth = if disasterRes and disasterRes.IsOk then disasterRes.Value.MaxHealth else nil,
		IsDead = AttributeDefinition.get(target, AttributeDefinition.IsDead),
		IsArmed = if disasterRes and disasterRes.IsOk then disasterRes.Value.IsArmed else nil,
		TeamId = AttributeDefinition.get(target, AttributeDefinition.TeamId),
	}
end

-- lit is how the first of its beams looks, they all go together
local function describeGrid(grid: Model): { [string]: any }
	local beamCount = 0
	local isLit: boolean? = nil
	for _, child in grid:GetChildren() do
		if child:IsA("BasePart") then
			beamCount += 1
			if isLit == nil then
				isLit = child.CanCollide == LaserGateDefinition.LIT.CanCollide
					and child.Transparency == LaserGateDefinition.LIT.Transparency
			end
		end
	end
	return {
		Name = grid:GetFullName(),
		Position = grid:GetPivot().Position,
		BeamCount = beamCount,
		IsLit = isLit,
	}
end
-- Class
local Module = {}

-- what a villain does to the town, driven by hand: one client can't be on both sides of it at once
Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"crime.get",
			"every disaster target of the map (its health, if it's down, if it's armed, the side it stands for) + every laser grid (lit or dark right now)",
			{},
			function(): Result<any, string>
				local targets: { any } = {}
				for _, target in MapDefinition.list(MapDefinition.DisasterTarget) do
					table.insert(targets, describeTarget(target))
				end
				local grids: { any } = {}
				for _, grid in MapDefinition.list(MapDefinition.LaserGate) do
					table.insert(grids, describeGrid(grid))
				end
				return Result.ok({
					Targets = targets,
					Grids = grids,
				})
			end
		),
		Harness.newCommand(
			"crime.hit",
			"a body hits a disaster target through the Attack effect, from wherever it stands: the rule of the game may turn it down (a hero, a menu, a place without fights). a puppet's hit is counted for nobody, so nobody is paid for it",
			{ FROM, DISASTER_ID, AMOUNT },
			function(args: { [string]: any }): Result<any, string>
				assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
				local fromRes = context.Bodies:Get(args.From)
				if fromRes.IsErr then
					return fromRes
				end
				local from = fromRes.Value
				local target = getTarget(args.DisasterId)
				if not target then
					return Result.err(`no target of "{args.DisasterId}" is in the world`)
				end
				if not TakeDownUtil.getIfAlive(from.Character) then
					return Result.err(`{from.Name} is down: no power hits from a body that's down`)
				end
				local priorHealth = AttributeDefinition.get(target, AttributeDefinition.Health)
				local isHostile = CombatDefinition.getIfHostile(from.Character, target)
				local scope = VFXService:NewScope(from.Player, from.Character)
				local isLanded = scope.fire(Attack, {
					Target = target,
					Amount = args.Amount,
				})
				local health = AttributeDefinition.get(target, AttributeDefinition.Health)
				return Result.ok({
					IsLanded = isLanded,
					IsHostile = isHostile,
					Taken = priorHealth - health,
					Health = health,
					IsDead = AttributeDefinition.get(target, AttributeDefinition.IsDead),
				})
			end
		),
		Harness.newCommand(
			"crime.alert",
			"puts a line on the alert strip through AlertService:Announce: of the one player named, or of every hero of the server. answers who was asked for",
			{ TEXT, TO },
			function(args: { [string]: any }): Result<any, string>
				assert(AlertService.IsInitialized, `the alert service isn't initialized`)
				if args.To == nil then
					AlertService:Announce(args.Text)
					return Result.ok({ To = "the heroes" })
				end
				local playerRes = context.Bodies:GetPlayer(args.To)
				if playerRes.IsErr then
					return playerRes
				end
				AlertService:Announce(args.Text, { playerRes.Value })
				return Result.ok({ To = playerRes.Value.Name })
			end
		),
	}
end

return Module
