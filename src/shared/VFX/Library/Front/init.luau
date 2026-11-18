--!strict
-- Services
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local SharedVFX = require("@game/ReplicatedStorage/Shared/VFX")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type SharedScope = VFXType.SharedScope
type SharedState<P> = VFXType.SharedState<P>
export type Properties = {
	CFrame: CFrame, -- where the box sets out from + how it's turned
	Velocity: Vector3, -- studs a second
	Size: Vector3,
	Lifetime: number, -- seconds it's on its way for at most
	OnHit: (target: Model) -> (), -- once per character for as long as the box is on
	OnExpired: (() -> ())?,
}
-- Constants
local isProperties = Type.strictInterface({
	CFrame = Type.CFrame,
	Velocity = AbilityType.FiniteVector3,
	Size = Type.Vector3,
	Lifetime = Type.numberPositive,
	OnHit = Type.callback,
	OnExpired = Type.optional(Type.callback),
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
-- a box on its way through the world in a straight line that tells of every character it runs into, the one it
-- belongs to aside. nothing stops it: it goes through whatever is in its way until its time is up. it's moved by the
-- clock rather than by physics, so it takes the same path on every machine that's given the same start
return SharedVFX.newState("Front", isProperties, function(props: Properties, scope: SharedScope)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	overlapParams.FilterDescendantsInstances = if scope.Character then { scope.Character } else {}
	local targets: { [Model]: true } = {}
	local age = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		age += deltaTime
		if age >= props.Lifetime then
			connection:Disconnect()
			if props.OnExpired then
				props.OnExpired()
			end
			return
		end
		for _, part in Workspace:GetPartBoundsInBox(props.CFrame + props.Velocity * age, props.Size, overlapParams) do
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
