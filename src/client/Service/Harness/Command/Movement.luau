--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local MovementService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Movement")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
-- Constants
-- seconds a lift is given to carry before the avatar is read
local SETTLE_DURATION = 0.3
-- Variables
-- References
-- Private Functions
-- how the avatar of this client moves, + the joints of every avatar in the game that hang loose on this screen
local function getState(): { [string]: any }
	assert(MovementService.IsInitialized, `the movement service isn't initialized`)
	local avatar = Players.LocalPlayer.Character
	local humanoid = avatar and avatar:FindFirstChildOfClass("Humanoid")
	local rootPart = avatar and avatar.PrimaryPart
	local limp: { [string]: { string } } = {}
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if not character then
			continue
		end
		local joints: { string } = {}
		for _, inst in character:GetDescendants() do
			if inst:IsA("Motor6D") and not inst.Enabled then
				table.insert(joints, inst.Name)
			end
		end
		if #joints > 0 then
			table.sort(joints)
			limp[player.Name] = joints
		end
	end
	return {
		IsSprinting = MovementService:GetIfSprinting(),
		WalkSpeed = if humanoid then humanoid.WalkSpeed else nil,
		State = if humanoid then humanoid:GetState().Name else nil,
		UseJumpPower = if humanoid then humanoid.UseJumpPower else nil,
		JumpPower = if humanoid then humanoid.JumpPower else nil,
		Height = if rootPart then rootPart.Position.Y else nil,
		VerticalSpeed = if rootPart then rootPart.AssemblyLinearVelocity.Y else nil,
		IsDead = AttributeDefinition.get(avatar, AttributeDefinition.IsDead),
		LimpJoints = limp,
	}
end
-- Class
local Module = {}

Module.list = function(): { Command }
	return {
		Harness.newCommand(
			"movement.get",
			"how this client's avatar moves: its walk speed + whether that's the run, its humanoid state, what it jumps with, how high its root is + how fast it rises. LimpJoints lists, by player, the joints that hang loose on this screen (somebody who's down)",
			{},
			function(): Result<any, string>
				return Result.ok(getState())
			end
		),
		Harness.newCommand(
			"movement.sprint",
			"goes from the walk to the run or back, the way a press of shift does. an error says why it was turned down: no avatar, behind a menu, less than a second after the last, or a pace that isn't the avatar's own (rooted, or under a power)",
			{},
			function(): Result<any, string>
				assert(MovementService.IsInitialized, `the movement service isn't initialized`)
				local sprintRes = MovementService:ToggleSprint()
				if sprintRes.IsErr then
					return Result.err(sprintRes.Value)
				end
				return Result.ok(getState())
			end
		),
		Harness.newCommand(
			"movement.lift",
			"the second jump: pushes the avatar up from where it is in the air. an error says why it was turned down: on the ground, a power jumps for it, or less than a second after the last. answers a third of a second later, as the push ends",
			{},
			function(): Result<any, string>
				assert(MovementService.IsInitialized, `the movement service isn't initialized`)
				local liftRes = MovementService:Lift()
				if liftRes.IsErr then
					return Result.err(liftRes.Value)
				end
				task.wait(SETTLE_DURATION)
				return Result.ok(getState())
			end
		),
	}
end

return Module
