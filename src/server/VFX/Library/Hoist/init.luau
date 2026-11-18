--!strict
-- Services
local RunService = game:GetService("RunService")
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local ServerVFX = require("@game/ServerScriptService/Server/VFX")
-- Types
export type Properties = {
	Target: Model,
	Height: number, -- studs above where it is that it's held at
	Duration: number, -- seconds until it's let go of
}
-- Constants
local isProperties = Type.strictInterface({
	Target = Type.instanceIsA("Model"),
	Height = Type.number,
	Duration = Type.numberPositive,
})
local POSITION_NAME = "HoistPosition"
-- enough to carry an avatar + hold it against whoever walks it, anything much heavier stays where it is
local MAX_FORCE = Vector3.one * 40_000
-- Variables
-- References
-- Private Functions
-- Class
-- picks a character up + holds it in the air on the spot, whoever it belongs to. the mover is made by the server +
-- worked out by whoever moves the character, so it holds a player just the same
return ServerVFX.newEvent("Hoist", isProperties, function(props: Properties): nil
	local target = props.Target
	local rootPart = target.PrimaryPart
	if not rootPart then
		return nil
	end
	if not RunService:IsRunning() then
		-- nothing is simulated in a place that isn't running, a story raises the character by hand
		local ground = target:GetPivot()
		target:PivotTo(ground + Vector3.yAxis * props.Height)
		task.delay(props.Duration, function()
			if target.Parent then
				target:PivotTo(ground)
			end
		end)
		return nil
	end
	-- a mover that's deprecated on purpose: the springy way it holds somebody is the feel the hold is meant to have
	local bodyPosition = Instance.new("BodyPosition")
	bodyPosition.Name = POSITION_NAME
	bodyPosition.MaxForce = MAX_FORCE
	bodyPosition.Position = rootPart.Position + Vector3.yAxis * props.Height
	bodyPosition.Parent = rootPart
	task.delay(props.Duration, function()
		bodyPosition:Destroy()
	end)
	return nil
end)
