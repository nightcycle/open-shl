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
	Range: number, -- studs ahead of the avatar that are felt out
}
-- Constants
local isProperties = Type.strictInterface({
	Range = Type.numberPositive,
})
-- Variables
-- References
-- Private Functions
-- Class
-- how many studs ahead of the middle of the avatar the first thing in its way is, nil with nothing in range. what a
-- client finds a wall with + what the server holds its word against, so both mean the same by being up against one
return SharedVFX.newEvent("Probe", isProperties, function(props: Properties, scope: SharedScope): number?
	local character = scope.Character
	local rootPart = character and character.PrimaryPart
	if not character or not rootPart then
		return nil
	end
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	raycastParams.IgnoreWater = true
	local result = Workspace:Raycast(rootPart.Position, rootPart.CFrame.LookVector * props.Range, raycastParams)
	return if result then result.Distance else nil
end)
