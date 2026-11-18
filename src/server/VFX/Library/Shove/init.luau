--!strict
-- Services
local RunService = game:GetService("RunService")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
export type Properties = {
	Target: Model,
	Velocity: Vector3, -- studs a second it's sent off at
}
-- Constants
local isProperties = Type.strictInterface({
	Target = Type.instanceIsA("Model"),
	Velocity = AbilityType.FiniteVector3,
})
-- seconds a story slides the target for + seconds until it's put back
local STORY_SLIDE_DURATION = 0.25
local STORY_RESET_DELAY = 1
-- Variables
-- References
-- Private Functions
-- Class
-- sends a character off at a pace, whoever it belongs to. it's a push rather than a pull: what becomes of it from
-- there is up to the ground under it + to whoever walks it
return ServerVFX.newEvent("Shove", isProperties, function(props: Properties): nil
	local target = props.Target
	local rootPart = target.PrimaryPart
	if not rootPart then
		return nil
	end
	if not RunService:IsRunning() then
		-- nothing is simulated in a place that isn't running, a story slides the character by hand
		local start = target:GetPivot()
		local elapsed = 0
		local connection: RBXScriptConnection
		connection = RunService.Heartbeat:Connect(function(deltaTime: number)
			elapsed += deltaTime
			if elapsed >= STORY_SLIDE_DURATION or not target.Parent then
				connection:Disconnect()
				return
			end
			target:PivotTo(target:GetPivot() + props.Velocity * deltaTime)
		end)
		task.delay(STORY_RESET_DELAY, function()
			connection:Disconnect()
			if target.Parent then
				target:PivotTo(start)
			end
		end)
		return nil
	end
	rootPart.AssemblyLinearVelocity = props.Velocity
	return nil
end)
