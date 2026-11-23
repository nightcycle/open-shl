--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Argument = require("@game/ServerScriptService/Server/Service/Harness/Argument")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local JailDefinition = require("@game/ServerScriptService/Server/Definition/Jail")
local JailService = require("@game/ServerScriptService/Server/Service/Jail")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
-- Types
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
-- how far above a road the look for its top starts, + how high over it the avatar is set down
local PROBE_HEIGHT = 50
local STAND_HEIGHT = 3
-- checks of the jail the avatar is given to be let go
local CHECK_COUNT = 3
-- Variables
-- References
-- Private Functions
-- the spot on a road that's closest to where the avatar is
local function getRoadPosition(from: Vector3): Vector3?
	local roads: { Instance } = {}
	for _, road in MapDefinition.list(MapDefinition.Road) do
		table.insert(roads, road)
	end
	local nearest: BasePart? = nil
	for _, road in roads do
		for _, part in road:GetDescendants() do
			if
				part:IsA("BasePart")
				and (not nearest or (part.Position - from).Magnitude < (nearest.Position - from).Magnitude)
			then
				nearest = part
			end
		end
	end
	if not nearest then
		return nil
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = roads
	local hit = Workspace:Raycast(
		nearest.Position + Vector3.new(0, PROBE_HEIGHT, 0),
		Vector3.new(0, -2 * PROBE_HEIGHT, 0),
		params
	)
	return if hit then hit.Position else nearest.Position
end
-- Class
local Module = {}

Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"jail.get",
			"whether the jail holds the avatar of a player, + whether it made trouble",
			{ Argument.Player },
			function(args: { [string]: any }): Result<any, string>
				assert(JailService.IsInitialized, `the jail service isn't initialized`)
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				local player = playerRes.Value
				return Result.ok({
					IsJailed = JailService:GetIfJailed(player),
					IsTroublesome = AttributeDefinition.get(player.Character, AttributeDefinition.IsTroublesome),
				})
			end
		),
		Harness.newCommand(
			"jail.release",
			"carries a held avatar onto the nearest road + waits for the jail's own check to let it go: getting away is the one way out",
			{ Argument.Player },
			function(args: { [string]: any }): Result<any, string>
				assert(JailService.IsInitialized, `the jail service isn't initialized`)
				local playerRes = context.Bodies:GetPlayer(args.Player)
				if playerRes.IsErr then
					return playerRes
				end
				local player = playerRes.Value
				local character = player.Character
				if not character or not JailService:GetIfJailed(player) then
					return Result.err(`the jail doesn't hold {player.Name}`)
				end
				local position = getRoadPosition(character:GetPivot().Position)
				if not position then
					return Result.err(`the map marks no road to carry {player.Name} to`)
				end
				character:PivotTo(CFrame.new(position + Vector3.new(0, STAND_HEIGHT, 0)))
				local deadline = os.clock() + CHECK_COUNT * JailDefinition.CHECK_INTERVAL
				while JailService:GetIfJailed(player) and os.clock() < deadline do
					task.wait()
				end
				if JailService:GetIfJailed(player) then
					return Result.err(
						`the jail still holds {player.Name} {CHECK_COUNT} checks after they were set on a road`
					)
				end
				return Result.ok({
					Position = position,
				})
			end
		),
	}
end

return Module
