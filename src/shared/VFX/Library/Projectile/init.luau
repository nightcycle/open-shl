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
	Origin: Vector3,
	Direction: Vector3, -- whatever its length, only where it points counts
	Speed: number, -- studs a second
	Lifetime: number, -- seconds it flies for at most
	Gravity: number?, -- studs a second it picks up downwards every second, none without
	IsPassingCharacters: boolean?, -- it flies through whoever is in its way, only the world stops it
	OnStep: ((position: Vector3) -> ())?,
	OnHit: ((result: RaycastResult) -> ())?,
	OnExpired: (() -> ())?,
}
-- Constants
local isProperties = Type.strictInterface({
	Origin = AbilityType.FiniteVector3,
	Direction = AbilityType.FiniteVector3,
	Speed = Type.numberPositive,
	Lifetime = Type.numberPositive,
	Gravity = Type.optional(Type.numberMin(0)),
	IsPassingCharacters = Type.optional(Type.boolean),
	OnStep = Type.optional(Type.callback),
	OnHit = Type.optional(Type.callback),
	OnExpired = Type.optional(Type.callback),
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
-- a point flying in a straight line, or an arc if it's pulled down, until it runs into something or its time is up.
-- it's moved by the clock rather than by physics, so it takes the same path on every machine that's given the same
-- start
return SharedVFX.newState("Projectile", isProperties, function(props: Properties, scope: SharedScope)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = if scope.Character then { scope.Character } else {}
	local direction = props.Direction.Unit
	-- how far it has dropped by the time it's a second old, by the square of its age from there
	local drop = Vector3.yAxis * -(props.Gravity or 0) / 2
	local position = props.Origin
	local age = 0
	local connection: RBXScriptConnection
	connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		local step = direction * props.Speed * deltaTime + drop * ((age + deltaTime) ^ 2 - age ^ 2)
		local result = Workspace:Raycast(position, step, raycastParams)
		-- whoever it flies through isn't in its way from then on
		while result and props.IsPassingCharacters do
			local character = getCharacter(result.Instance)
			if not character then
				break
			end
			raycastParams:AddToFilter(character)
			result = Workspace:Raycast(position, step, raycastParams)
		end
		if result then
			connection:Disconnect()
			if props.OnStep then
				props.OnStep(result.Position)
			end
			if props.OnHit then
				props.OnHit(result)
			end
			return
		end
		position += step
		age += deltaTime
		if props.OnStep then
			props.OnStep(position)
		end
		if age >= props.Lifetime then
			connection:Disconnect()
			if props.OnExpired then
				props.OnExpired()
			end
		end
	end)
	return function()
		connection:Disconnect()
	end
end)
