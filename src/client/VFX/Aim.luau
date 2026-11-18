--!strict
-- Services
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type Aim = AbilityType.Aim
-- Constants
local RANGE = 1000
-- Variables
-- a story has no mouse to point with, it says where the aim goes instead
local Override: Vector3? = nil
-- References
-- Private Functions
-- Class
local Module = {}

Module.setOverride = function(position: Vector3?)
	Override = position
end

-- what the pointer of the player is over in the world, seen past their own avatar
Module.get = function(character: Model?): Aim
	local camera = Workspace.CurrentCamera
	local origin = if camera then camera.CFrame.Position else Vector3.zero
	if Override then
		return table.freeze({ Origin = origin, Position = Override })
	end
	if not camera then
		return table.freeze({ Origin = origin, Position = origin })
	end
	local pointer = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(pointer.X, pointer.Y)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = if character then { character } else {}
	local result = Workspace:Raycast(ray.Origin, ray.Direction * RANGE, raycastParams)
	return table.freeze({
		Origin = ray.Origin,
		Position = if result then result.Position else ray.Origin + ray.Direction * RANGE,
	})
end

return Module
