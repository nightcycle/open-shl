--!strict
-- Services
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local SharedVFX = require("@game/ReplicatedStorage/Shared/VFX")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type SharedScope = VFXType.SharedScope
type SharedState<P> = VFXType.SharedState<P>
export type Properties = {
	Part: BasePart, -- what the box is carried around by
	Size: Vector3,
	Offset: CFrame?, -- of the box from the part
	OnHit: (target: Model) -> (), -- once per character for as long as the box is on
}
-- Constants
local isProperties = Type.strictInterface({
	Part = Type.instanceIsA("BasePart"),
	Size = Type.Vector3,
	Offset = Type.optional(Type.CFrame),
	OnHit = Type.callback,
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
-- a box that follows a part + tells of every character it runs into, the one it belongs to aside
return SharedVFX.newState("Hitbox", isProperties, function(props: Properties, scope: SharedScope)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = if scope.Character then { scope.Character } else {}
	local offset = props.Offset or CFrame.identity
	local targets: { [Model]: true } = {}
	local connection = RunService.Heartbeat:Connect(function()
		for _, part in Workspace:GetPartBoundsInBox(props.Part.CFrame * offset, props.Size, overlapParams) do
			local target = getCharacter(part)
			if target and not targets[target] then
				targets[target] = true
				task.spawn(props.OnHit, target)
			end
		end
	end)
	return function()
		connection:Disconnect()
	end
end)
