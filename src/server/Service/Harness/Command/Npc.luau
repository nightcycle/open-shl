--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
local NpcDefinition = require("@game/ServerScriptService/Server/Definition/Npc")
local NpcService = require("@game/ServerScriptService/Server/Service/Npc")
-- Types
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
local MAX_COUNT = NpcDefinition.MAX_COUNT
local NPC_ID = Harness.optional(
	Harness.newArgument("NpcId", "string", Type.string, "which kind of body, the first the game lists when left out")
)
local COUNT = Harness.optional(
	Harness.newArgument(
		"Count",
		"number",
		Type.intersection(Type.integer, Type.numberConstrained(1, MAX_COUNT)),
		`how many, a whole wave of {MAX_COUNT} when left out`
	)
)
local NEAR = Harness.optional(
	Harness.newArgument(
		"Near",
		"string",
		Type.string,
		"the player they come up in a ring around, whoever is alone on the server when left out"
	)
)
local DISTANCE = Harness.optional(
	Harness.newArgument(
		"Distance",
		"number",
		Type.numberPositive,
		"studs from that player to the ring, 40 when left out"
	)
)
local LIFETIME = Harness.optional(
	Harness.newArgument("Lifetime", "number", Type.numberPositive, "seconds until they're taken away, 90 when left out")
)
local IS_AT_SPAWNS = Harness.optional(
	Harness.newArgument(
		"IsAtSpawns",
		"boolean",
		Type.boolean,
		"true for the graves the map marks, all over the town, instead of a ring around a player"
	)
)
local DEFAULT_DISTANCE = 40
-- what a wave of its old place was given, + how far over the spot it's asked for each of it came in
local DEFAULT_LIFETIME = 90
local RISE = Vector3.new(0, 4, 0)
-- Variables
-- References
-- Private Functions
local function describe(model: Model): { [string]: any }
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	return {
		Name = model.Name,
		Position = model:GetPivot().Position,
		Health = AttributeDefinition.get(model, AttributeDefinition.Health),
		IsDead = AttributeDefinition.get(model, AttributeDefinition.IsDead),
		State = if humanoid then humanoid:GetState().Name else nil,
		WalkToPoint = if humanoid then humanoid.WalkToPoint else nil,
		IsFollowing = humanoid ~= nil and humanoid.WalkToPart ~= nil,
	}
end
-- Class
local Module = {}

-- the bodies nobody plays, set on the town by hand: nothing of the game raises a wave before one was seen to walk
Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"npc.raise",
			"puts bodies nobody plays into the world through NpcService:Spawn, in a ring around a player or at the graves of the map. answers how many came + how many walk the map now",
			{ NPC_ID, COUNT, NEAR, DISTANCE, LIFETIME, IS_AT_SPAWNS },
			function(args: { [string]: any }): Result<any, string>
				assert(NpcService.IsInitialized, `the npc service isn't initialized`)
				local npcId: string = args.NpcId or NpcDefinition.list()[1].Id
				local npcRes = NpcDefinition.get(npcId)
				if npcRes.IsErr then
					return Result.err(npcRes.Value)
				end
				local count: number = args.Count or MAX_COUNT
				local cframes: { CFrame } = {}
				if args.IsAtSpawns then
					for _, spawn in MapDefinition.list(MapDefinition.ZombieSpawn) do
						if #cframes < count then
							table.insert(cframes, spawn.CFrame + RISE)
						end
					end
				else
					local playerRes = context.Bodies:GetPlayer(args.Near)
					if playerRes.IsErr then
						return playerRes
					end
					local avatar = playerRes.Value.Character
					if not avatar then
						return Result.err(`{playerRes.Value.Name} has no avatar to put them around`)
					end
					local center = avatar:GetPivot().Position
					local distance: number = args.Distance or DEFAULT_DISTANCE
					for index = 1, count do
						local angle = index / count * math.pi * 2
						local offset = Vector3.new(math.cos(angle), 0, math.sin(angle)) * distance
						table.insert(cframes, CFrame.new(center + offset + RISE))
					end
				end
				local raisedCount = 0
				for _, cframe in cframes do
					if NpcService:Spawn(npcId, cframe, args.Lifetime or DEFAULT_LIFETIME) then
						raisedCount += 1
					end
				end
				return Result.ok({
					NpcId = npcId,
					Raised = raisedCount,
					Asked = #cframes,
					Count = NpcService:GetCount(),
				})
			end
		),
		Harness.newCommand(
			"npc.list",
			"every body nobody plays that walks the map: where it is, its health, what its humanoid is doing + where it's sent",
			{},
			function(): Result<any, string>
				assert(NpcService.IsInitialized, `the npc service isn't initialized`)
				local out: { any } = {}
				for _, model in NpcService:List() do
					table.insert(out, describe(model))
				end
				return Result.ok(out)
			end
		),
		Harness.newCommand(
			"npc.clear",
			"takes every body nobody plays out of the world, answers how many went",
			{},
			function(): Result<any, string>
				assert(NpcService.IsInitialized, `the npc service isn't initialized`)
				return Result.ok(NpcService:Clear())
			end
		),
	}
end

return Module
