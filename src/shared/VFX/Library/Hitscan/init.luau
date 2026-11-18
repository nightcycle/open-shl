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
	Origin: Vector3,
	Direction: Vector3, -- whatever its length, only where it points counts
	Range: number, -- studs it gets to at most
	IsPassingCharacters: boolean?, -- it goes through whoever is in its way, only the world stops it
}
export type Result = {
	Position: Vector3, -- where it ended: at what it ran into, as far as it gets without
	Distance: number, -- studs from where it left to there
	Instance: BasePart?, -- what it ran into
	Target: Model?, -- the character that's a part of, if it's one
}
-- Constants
-- studs something that's let go at once gets to at most, whatever asks
local MAX_RANGE = 2000
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
local isProperties = Type.strictInterface({
	Origin = AbilityType.FiniteVector3,
	Direction = isDirection,
	Range = Type.numberConstrainedExclusive(0, MAX_RANGE),
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
-- something that crosses its whole range at once: what the first thing in its way is + how far off. the character it
-- belongs to is never in its way, water is. what a client lets a ray go with + what the server holds its word against,
-- so both mean the same by something being in the way
return SharedVFX.newEvent("Hitscan", isProperties, function(props: Properties, scope: SharedScope): Result
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = if scope.Character then { scope.Character } else {}
	local step = props.Direction.Unit * props.Range
	local result = Workspace:Raycast(props.Origin, step, raycastParams)
	-- whoever it goes through isn't in its way from then on
	while result and props.IsPassingCharacters do
		local character = getCharacter(result.Instance)
		if not character then
			break
		end
		raycastParams:AddToFilter(character)
		result = Workspace:Raycast(props.Origin, step, raycastParams)
	end
	if not result then
		return {
			Position = props.Origin + step,
			Distance = props.Range,
		}
	end
	return {
		Position = result.Position,
		Distance = result.Distance,
		Instance = result.Instance,
		Target = getCharacter(result.Instance),
	}
end)
