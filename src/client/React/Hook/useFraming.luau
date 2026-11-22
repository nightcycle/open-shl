--!strict
--!native
-- Services
local RunService = game:GetService("RunService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
-- how the camera of a stage gives way to the height of whoever stands on it
export type Rule = {
	-- the point a plain body is looked at, off the spot it stands on
	TargetOffset: Vector3,
	-- how much of what a body is taller or shorter than the plain one the camera makes up for. at 0 it never moves,
	-- at 1 every body is drawn the same size
	Follow: number,
	-- how long it takes to get to a new framing, at a steady pace
	Duration: number,
	-- the first framing is moved to as well, from wherever the camera was put. it's cut to otherwise
	IsEasedIn: boolean?,
}
-- Constants
-- a body that was never sized is the plain one
local DEFAULT_HEIGHT = 1
-- Variables
-- References
-- Private Functions
-- from where + at what a body of that height is looked at. both keep to the spot the body stands on, so its feet
-- stay where they are in the picture however far the camera is off them
local function getFraming(mount: Vector3, anchor: CFrame, height: number, rule: Rule): CFrame
	local reach = 1 + rule.Follow * (height - DEFAULT_HEIGHT)
	return CFrame.lookAt(
		mount + (mount - anchor.Position) * (reach - 1),
		anchor:PointToWorldSpace(rule.TargetOffset * reach)
	)
end
-- Class
-- the camera looks from the mount of a stage at whoever stands on its spot: it backs off a taller body + looks higher
-- up, + comes closer to a shorter one. a plain body is looked at from the mount itself
return function(cameraRef: { current: Camera? }, mount: BasePart?, anchor: BasePart?, height: number, rule: Rule)
	-- whether the camera was put anywhere yet
	local isFramedRef = React.useRef(false)
	React.useEffect(function()
		local camera = cameraRef.current
		if not camera or not mount or not anchor then
			return function() end
		end
		local to = getFraming(mount.Position, anchor.CFrame, height, rule)
		local isFramed = isFramedRef.current
		isFramedRef.current = true
		if not isFramed and not rule.IsEasedIn then
			camera.CFrame = to
			return function() end
		end
		local from = camera.CFrame
		local startClock = os.clock()
		local connection: RBXScriptConnection
		connection = RunService.RenderStepped:Connect(function()
			local alpha = math.min((os.clock() - startClock) / rule.Duration, 1)
			camera.CFrame = from:Lerp(to, alpha)
			if alpha == 1 then
				connection:Disconnect()
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { mount :: any, anchor, height })
end
