--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local FurnitureDefinition = require("@game/ReplicatedStorage/Shared/Definition/Furniture")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
-- Constants
local PLACEMENT = FurnitureDefinition.PLACEMENT
local FULL_TURN_DEG = 360
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

function Util.snap(value: number, increment: number): number
	return math.round(value / increment) * increment
end

-- X + Z are in studs from the middle of the pad
function Util.newCFrame(x: number, z: number, rotationDeg: number): CFrame
	return CFrame.new(Util.snap(x, PLACEMENT.GRID_SIZE), PLACEMENT.PAD_HEIGHT_OFFSET, Util.snap(z, PLACEMENT.GRID_SIZE))
		* CFrame.Angles(0, math.rad(Util.snap(rotationDeg, PLACEMENT.ROTATION_INC_DEG) % FULL_TURN_DEG), 0)
end

function Util.getRotationDeg(cframe: CFrame): number
	local _, yaw = cframe:ToOrientation()
	return Util.snap(math.deg(yaw), PLACEMENT.ROTATION_INC_DEG) % FULL_TURN_DEG
end

function Util.nudge(cframe: CFrame, direction: Vector3): CFrame
	local position = cframe * (direction * PLACEMENT.NUDGE_DISTANCE)
	return Util.newCFrame(position.X, position.Z, Util.getRotationDeg(cframe))
end

function Util.turn(cframe: CFrame): CFrame
	return Util.newCFrame(cframe.X, cframe.Z, Util.getRotationDeg(cframe) + PLACEMENT.ROTATION_INC_DEG)
end

-- scripts are stripped + seats disabled
function Util.newModel(furnitureId: string): Result<Model, string>
	local definitionRes = FurnitureDefinition.get(furnitureId)
	if definitionRes.IsErr then
		return Result.err(`model of "{furnitureId}" failed: {definitionRes.Value}`)
	end
	local templateRes = FurnitureDefinition.getTemplate(furnitureId)
	if templateRes.IsErr then
		return Result.err(`model of "{furnitureId}" failed: {templateRes.Value}`)
	end
	local template = templateRes.Value
	if not template:IsA("Model") or not template.PrimaryPart then
		return Result.err(`model of "{furnitureId}" failed: expected a Model with a primary part`)
	end
	local out = template:Clone()
	out.Name = definitionRes.Value.Name
	for _, desc in out:GetDescendants() do
		if desc:IsA("LuaSourceContainer") then
			desc:Destroy()
		elseif desc:IsA("VehicleSeat") then
			desc.Disabled = true
		end
	end
	return Result.ok(out)
end

return Util
