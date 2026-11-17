--!strict
-- Services
local TweenService = game:GetService("TweenService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the instance is tweened to the goal whenever one of the deps changes
return function(ref: { current: Instance? }, tweenInfo: TweenInfo, goal: { [string]: any }, deps: { any })
	React.useEffect(function()
		local inst = ref.current
		if not inst then
			return function() end
		end
		local tween = TweenService:Create(inst, tweenInfo, goal)
		tween:Play()
		return function()
			tween:Cancel()
			tween:Destroy()
		end
	end, deps)
end
