--!strict
-- Services
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
	Position: Vector3,
	Range: number, -- studs from the middle of the character
}
-- Constants
local isProperties = Type.strictInterface({
	Position = AbilityType.FiniteVector3,
	Range = Type.numberMin(0),
})
-- Variables
-- References
-- Private Functions
-- Class
-- whether a spot is within reach of the character the effect belongs to. what a client predicts with + what the
-- server holds a claim against, so the range a hit is refused at is the same one it was aimed with
return SharedVFX.newEvent("Reach", isProperties, function(props: Properties, scope: SharedScope): boolean
	local character = scope.Character
	if not character then
		return false
	end
	return (character:GetPivot().Position - props.Position).Magnitude <= props.Range
end)
