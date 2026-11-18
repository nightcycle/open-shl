--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local SharedVFX = require("@game/ReplicatedStorage/Shared/VFX")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type SharedScope = VFXType.SharedScope
type SharedEvent<P, R> = VFXType.SharedEvent<P, R>
export type Properties = {
	Range: number, -- studs from the middle of the character
}
-- Constants
local isProperties = Type.strictInterface({
	Range = Type.numberPositive,
})
-- Variables
-- References
-- Private Functions
local function getCharacter(part: BasePart): Model?
	local model = part:FindFirstAncestorWhichIsA("Model")
	while model do
		if model:FindFirstChildWhichIsA("Humanoid") then
			return model
		end
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return nil
end
-- Class
-- every other character around the one the effect belongs to. each is held to its middle, the way a reach is: one
-- that only sticks a limb into range isn't in it, so whoever is found here is within the same reach on the server
return SharedVFX.newEvent("Nearby", isProperties, function(props: Properties, scope: SharedScope): { Model }
	local character = scope.Character
	if not character then
		return {}
	end
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = { character }
	local position = character:GetPivot().Position
	local found: { [Model]: true } = {}
	local targets: { Model } = {}
	for _, part in Workspace:GetPartBoundsInRadius(position, props.Range, overlapParams) do
		local target = getCharacter(part)
		if not target or found[target] then
			continue
		end
		found[target] = true
		if (target:GetPivot().Position - position).Magnitude <= props.Range then
			table.insert(targets, target)
		end
	end
	return targets
end)
