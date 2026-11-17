--!strict
--!native
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local React = require("@game/ReplicatedStorage/Packages/React")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
-- Modules
local IntroCamera = require("@game/StarterPlayer/StarterPlayerScripts/Client/Class/IntroCamera")
local PunDefinition = require("@game/ReplicatedStorage/Shared/Definition/Pun")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local Intro = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Intro")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
local useLocalCharacter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useLocalCharacter")
-- Contexts
-- Types
type IntroCamera = IntroCamera.IntroCamera
export type Properties = {}
-- Constants
local WAY_POINT_PATH = "game/Workspace/Map/intro-cam"
-- how long the map gets to show up, without the way-points the intro plays over the default camera
local WAY_POINT_TIMEOUT = 5
-- the intro is over in about 11 seconds, whatever breaks along the way doesn't keep the player in it
local TIME_CAP = 20
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local pun = React.useMemo(function(): string
		return PunDefinition.roll(Random.new())
	end, {})
	local character = useLocalCharacter()
	local characterRef = React.useRef(character)
	characterRef.current = character
	local cameraRef: { current: IntroCamera? } = React.useRef(nil :: IntroCamera?)
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
				warn(`no intro way-points at {WAY_POINT_PATH}`)
				return
			end
			local cameraRes = IntroCamera.new(wayPoints)
			if cameraRes.IsErr then
				warn(`intro camera err: {cameraRes.Value}`)
				return
			end
			cameraRef.current = cameraRes.Value
		end)
		task.delay(TIME_CAP, function()
			if isMountedRef.current then
				finish()
			end
		end)
		return function()
			-- however the intro ends, the camera is the avatar's again
			local camera = cameraRef.current
			cameraRef.current = nil
			if camera and camera.IsAlive then
				camera:Destroy()
			end
		end
	end, {})

	return e(
		Intro,
		{
			Size = UDim2.fromScale(1, 1),
			Pun = pun,
			OnAction = function(action: Intro.ActionInfo)
				if action.Type == "FadedOut" then
					task.spawn(function()
						local camera = cameraRef.current
						local avatar = characterRef.current
						local head = avatar and avatar:FindFirstChild("Head")
						if camera and camera.IsAlive and head and head:IsA("BasePart") then
							Future.awaitUntil(camera:FlyTo(head.CFrame), function(): boolean
								return not isMountedRef.current
							end)
						end
						finish()
					end)
				end
			end,
		} :: Intro.Properties
	)
end
