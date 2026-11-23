--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Argument = require("@game/ServerScriptService/Server/Service/Harness/Argument")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local HarnessTypes = require("@game/ServerScriptService/Server/Service/Harness/Types")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
type Context = HarnessTypes.Context
-- Constants
-- Variables
-- References
-- Private Functions
local function listTools(parent: Instance?): { string }
	local names: { string } = {}
	if parent then
		for _, child in parent:GetChildren() do
			if child:IsA("Tool") then
				table.insert(names, child.Name)
			end
		end
	end
	return names
end
-- Class
local Module = {}

Module.list = function(context: Context): { Command }
	return {
		Harness.newCommand(
			"avatar.get",
			"the state of an avatar or a puppet: every attribute of the game on it, its health, its tools, its fight",
			{ Argument.Body },
			function(args: { [string]: any }): Result<any, string>
				assert(SessionService.IsInitialized, `the session service isn't initialized`)
				assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
				local bodyRes = context.Bodies:Get(args.Body)
				if bodyRes.IsErr then
					return bodyRes
				end
				local body = bodyRes.Value
				local character, player = body.Character, body.Player
				-- read through the definition, so one that was never written says its default
				local attributes: { [string]: any } = {}
				for _, attribute in AttributeDefinition.list("Character") do
					attributes[attribute.Name] = AttributeDefinition.get(character, attribute)
				end
				local now = CombatDefinition.getTime()
				local fightingUntil = AttributeDefinition.get(character, AttributeDefinition.FightingUntil)
				local isFighting = CombatDefinition.getIfFighting(fightingUntil, now)
				local humanoid = character:FindFirstChildWhichIsA("Humanoid")
				local costumeOpt = if player then AvatarService:GetCostume(player) else nil
				return Result.ok({
					Name = body.Name,
					IsPuppet = player == nil,
					Attributes = attributes,
					IsFighting = isFighting,
					-- seconds of the fight that are left, on the clock FightingUntil is on
					FightingFor = if isFighting and fightingUntil then fightingUntil - now else 0,
					Humanoid = if humanoid
						then {
							Health = humanoid.Health,
							MaxHealth = humanoid.MaxHealth,
							WalkSpeed = humanoid.WalkSpeed,
							State = humanoid:GetState(),
						}
						else nil,
					Position = character:GetPivot().Position,
					IsShielded = character:FindFirstChildWhichIsA("ForceField") ~= nil,
					ToolsInHand = listTools(character),
					ToolsInBackpack = listTools(if player then player:FindFirstChildOfClass("Backpack") else nil),
					-- the engine's team, + what only the server knows of the avatar of a player
					Team = if player and player.Team then player.Team.Name else nil,
					IsInMenu = if player then SessionService:GetIfInMenu(player) else nil,
					IsHeld = if player then AvatarService:GetIfHeld(player) else nil,
					IsMasked = if player then AvatarService:GetIfMasked(player) else nil,
					Costume = if costumeOpt and costumeOpt.IsSome then costumeOpt.Value else nil,
				})
			end
		),
	}
end

return Module
