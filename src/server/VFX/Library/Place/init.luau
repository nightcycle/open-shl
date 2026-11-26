--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
export type Properties = {
	Target: Model, -- whoever is moved, the character the effect belongs to or anybody else
	Position: Vector3, -- where the middle of them ends up
}
-- Constants
local isProperties = Type.strictInterface({
	Target = Type.instanceIsA("Model"),
	Position = AbilityType.FiniteVector3,
})
-- Variables
-- References
-- Private Functions
-- Class
-- puts a character somewhere else, upright + turned the way it was. it's the server that moves them, their own
-- client isn't asked: this is for a body whose player didn't choose to go, an avatar that did goes by the warp of
-- its own client. true if they were moved: nobody who's down or sat goes anywhere. where they may be put + whether
-- one character may move another is asked by whoever fires it
return ServerVFX.newEvent("Place", isProperties, function(props: Properties): boolean
	local target = props.Target
	local humanoid = target:FindFirstChildWhichIsA("Humanoid")
	if
		not humanoid
		or humanoid.Health <= 0
		or humanoid.SeatPart ~= nil
		or AttributeDefinition.get(target, AttributeDefinition.IsDead)
	then
		return false
	end
	local _, heading = target:GetPivot():ToOrientation()
	target:PivotTo(CFrame.new(props.Position) * CFrame.Angles(0, heading, 0))
	return true
end)
