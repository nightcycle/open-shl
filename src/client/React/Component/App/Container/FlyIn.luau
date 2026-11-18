--!strict
--!native
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local FlyInCamera = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/FlyInCamera")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local FlyIn = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/FlyIn")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
-- Contexts
-- Types
type FlyInCamera = FlyInCamera.FlyInCamera
export type Properties = {}
-- Constants
local WAY_POINT_PATH = "game/Workspace/Map/Cameras"
-- how long the map gets to show up, without the way-points the logo plays over the default camera
local WAY_POINT_TIMEOUT = 5
-- how long the logo is given where there's nothing to fly along
local FALLBACK_DURATION = 1
-- the flight is over in about 10 seconds, whatever breaks along the way doesn't keep the player in it
local TIME_CAP = 20
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	-- the flight says how long it takes once it's made, the screen plays by it
	local duration: number?, setDuration: (number?) -> () = React.useState(nil :: number?)
	local cameraRef: { current: FlyInCamera? } = React.useRef(nil :: FlyInCamera?)
	local isMountedRef = useIsMounted()

	local function finish()
		local camera = cameraRef.current
		cameraRef.current = nil
		if camera and camera.IsAlive then
			camera:Destroy()
		end
		if isMountedRef.current and ShellService.IsInitialized then
			ShellService:FinishBootPhase("Intro")
		end
	end

	React.useEffect(function()
		-- the map may still be on its way
		task.spawn(function()
			local wayPoints = IndexUtil.waitForPath(WAY_POINT_PATH, WAY_POINT_TIMEOUT, nil, true)
			if not isMountedRef.current then
				return
			end
			if not wayPoints then
				warn(`no fly-in way-points at {WAY_POINT_PATH}`)
				setDuration(FALLBACK_DURATION)
				return
			end
			local cameraRes = FlyInCamera.new(wayPoints)
			if cameraRes.IsErr then
				warn(`fly-in camera err: {cameraRes.Value}`)
				setDuration(FALLBACK_DURATION)
				return
			end
			local camera = cameraRes.Value
			cameraRef.current = camera
			if camera.IsAlive then
				setDuration(camera.Duration)
			end
		end)
		task.delay(TIME_CAP, function()
			if isMountedRef.current then
				finish()
			end
		end)
		return function()
			-- however the flight ends, the camera is the avatar's again
			local camera = cameraRef.current
			cameraRef.current = nil
			if camera and camera.IsAlive then
				camera:Destroy()
			end
		end
	end, {})

	return e(
		FlyIn,
		{
			Size = UDim2.fromScale(1, 1),
			Duration = duration,
			OnAction = function(action: FlyIn.ActionInfo)
				if action.Type == "FadedOut" then
					finish()
				end
			end,
		} :: FlyIn.Properties
	)
end
