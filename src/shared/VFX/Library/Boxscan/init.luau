--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local SharedVFX = require("@game/ReplicatedStorage/Shared/VFX")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type SharedScope = VFXType.SharedScope
type SharedEvent<P, R> = VFXType.SharedEvent<P, R>
export type Properties = {
	CFrame: CFrame, -- where the box sets out, turned the way it stays all the way
	Size: Vector3,
	Direction: Vector3, -- whatever its length, only where it points counts
	Range: number, -- studs it gets to at most
	IsPassingCharacters: boolean?, -- it goes through whoever is in its way, only the world stops it
}
export type Result = {
	-- studs it gets before any of it runs into something: none where it sets out in it, the range without
	Distance: number,
	Instance: BasePart?, -- what it ran into
}
-- Constants
-- studs the engine sweeps a box at most
local MAX_RANGE = 1024
-- studs across a box that's swept at most
local MAX_SIZE = 64
local isDirection = function(value: unknown): (boolean, string?)
	local success, msg = AbilityType.FiniteVector3(value)
	if not success then
		return false, msg
	end
	if (value :: Vector3).Magnitude <= 0 then
		return false, `a direction that points somewhere expected`
	end
	return true
end
local isSize = function(value: unknown): (boolean, string?)
	local success, msg = AbilityType.FiniteVector3(value)
	if not success then
		return false, msg
	end
	local size = value :: Vector3
	if math.min(size.X, size.Y, size.Z) <= 0 or math.max(size.X, size.Y, size.Z) > MAX_SIZE then
		return false, `a size within {MAX_SIZE} studs expected, got {size}`
	end
	return true
end
local isProperties = Type.strictInterface({
	CFrame = Type.CFrame,
	Size = isSize,
	Direction = isDirection,
	Range = Type.numberConstrained(0, MAX_RANGE),
	IsPassingCharacters = Type.optional(Type.boolean),
})
-- Variables
-- References
-- Private Functions
local function getCharacter(inst: Instance): Model?
	local model = inst:FindFirstAncestorWhichIsA("Model")
	while model do
		if model:FindFirstChildWhichIsA("Humanoid") then
			return model
		end
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return nil
end
-- Class
-- a box that crosses its whole range at once without turning: how far it gets before any of it runs into something.
-- a sweep doesn't tell of what the box already stands in, so that's looked for first. the character it belongs to is
-- never in its way. what a ray is to a point this is to something with a size: a wall, a crate, a body
return SharedVFX.newEvent("Boxscan", isProperties, function(props: Properties, scope: SharedScope): Result
	local ignored: { Instance } = if scope.Character then { scope.Character } else {}
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = ignored
	for _, part in Workspace:GetPartBoundsInBox(props.CFrame, props.Size, overlapParams) do
		if not (props.IsPassingCharacters and getCharacter(part)) then
			return {
				Distance = 0,
				Instance = part,
			}
		end
	end
	if props.Range <= 0 then
		return {
			Distance = 0,
		}
	end
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = ignored
	local step = props.Direction.Unit * props.Range
	local result = Workspace:Blockcast(props.CFrame, props.Size, step, raycastParams)
	-- whoever it goes through isn't in its way from then on
	while result and props.IsPassingCharacters do
		local character = getCharacter(result.Instance)
		if not character then
			break
		end
		raycastParams:AddToFilter(character)
		result = Workspace:Blockcast(props.CFrame, props.Size, step, raycastParams)
	end
	if not result then
		return {
			Distance = props.Range,
		}
	end
	return {
		Distance = result.Distance,
		Instance = result.Instance,
	}
end)
