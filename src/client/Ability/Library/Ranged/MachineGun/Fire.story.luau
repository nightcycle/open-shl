--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
-- Modules
local Ability = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/MachineGun")
local AbilityStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Story")
local Client = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/MachineGun")
local RayFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Ray")
local Server = require("@game/ServerScriptService/Server/Ability/Library/Ranged/MachineGun")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the ray the user lets go at the target from the muzzle, as their client would word it
return AbilityStory.new(Client, Server, Ability.Layout.Bindings.Fire, {
	GetPayload = function(stage: AbilityStory.Stage)
		local limb = stage.User:FindFirstChild(Ability.Config.Limb)
		local spot = RayFactory.getOffset(Ability.Config, 1) or Vector3.zero
		local origin = if limb and limb:IsA("BasePart")
			then limb.CFrame:PointToWorldSpace(spot)
			else stage.User:GetPivot().Position
		local offset = stage.Target:GetPivot().Position - origin
		return {
			Id = 1,
			Origin = origin,
			Direction = offset.Unit,
			Distance = math.min(offset.Magnitude, Ability.Config.Range),
			Target = stage.Target,
		}
	end,
})
