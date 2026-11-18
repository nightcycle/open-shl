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
-- the panel grows to its size out of the point it's anchored at, once it's there + the delay has passed. it's only
-- told what it starts out as, from there on the tween sizes it
return function(size: UDim2, tweenInfo: TweenInfo, delay: number?): ({ current: GuiObject? }, UDim2)
	local ref: { current: GuiObject? } = React.useRef(nil :: GuiObject?)
	local initialSizeRef = React.useRef(UDim2.new())
	React.useEffect(function()
		local inst = ref.current
		if not inst then
			return function() end
		end
		local isDead = false
		local tween = TweenService:Create(inst, tweenInfo, {
			Size = size,
		})
		if delay then
			task.delay(delay, function()
				if not isDead then
					tween:Play()
				end
			end)
		else
			tween:Play()
		end
		return function()
			isDead = true
			tween:Cancel()
			tween:Destroy()
		end
	end, { size })

	return ref, initialSizeRef.current
end
