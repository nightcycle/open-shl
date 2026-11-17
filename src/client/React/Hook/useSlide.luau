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
-- the frame slides in once it's there + back out when it's closed, onClosed is called once it's gone
return function(
	openPosition: UDim2,
	closedPosition: UDim2,
	tweenInfo: TweenInfo,
	onClosed: () -> ()
): ({ current: Frame? }, UDim2, () -> ())
	local isClosing, setIsClosing = React.useState(false)
	local frameRef: { current: Frame? } = React.useRef(nil :: Frame?)
	-- the frame is only told where it starts out, from there on it slides to where it belongs
	local initialPositionRef = React.useRef(closedPosition)
	local onClosedRef = React.useRef(onClosed)
	onClosedRef.current = onClosed
	React.useEffect(function()
		local inst = frameRef.current
		if not inst then
			return function() end
		end
		local tween = TweenService:Create(inst, tweenInfo, {
			Position = isClosing and closedPosition or openPosition,
		})
		-- the frame is only gone once it slid back out, a slide that was cut short doesn't count
		local connection = tween.Completed:Connect(function(playbackState: Enum.PlaybackState)
			if isClosing and playbackState == Enum.PlaybackState.Completed then
				onClosedRef.current()
			end
		end)
		tween:Play()
		return function()
			connection:Disconnect()
			tween:Cancel()
			tween:Destroy()
		end
	end, { isClosing :: any, openPosition })

	return frameRef, initialPositionRef.current, function()
		setIsClosing(true)
	end
end
