--!strict
--!native
-- Services
local RunService = game:GetService("RunService")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local AppearanceConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance")
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
-- Components
-- Hooks
local useAppearance = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useAppearance")
local useScene = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useScene")
-- Contexts
local AppTopInsetContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/TopInset")
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local IsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/IsHeroFocus")
local PreviewCharacterContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Preview")
-- Types
export type Properties = {}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/TabbedEditor/CONSTANTS")
local EMPTY_APPEARANCE = AppearanceConstructor.new()
local TURN_SPEED_DEG = CONSTANTS.TURN_STEP_DEG / CONSTANTS.TURN_DURATION
-- Variables
-- References
local HeroSceneTemplate = IndexUtil.waitForPath("game/ReplicatedStorage/lib/scene/hero-character-editor") :: Folder
local SecretSceneTemplate = IndexUtil.waitForPath("game/ReplicatedStorage/lib/scene/secret-character-editor") :: Folder
-- Private Functions
local e = React.createElement

local function useWorldModel(scene: useScene.Scene?, worldModelRef: { current: WorldModel? })
	React.useEffect(function()
		local worldModel = worldModelRef.current
		if scene and scene.IsAlive and worldModel then
			scene.Instance.Parent = worldModel
		end
		return function() end
	end, { scene })
end

local function getRig(scene: useScene.Scene?): Model?
	return if scene and scene.IsAlive and scene.Rig.IsDone then scene.Rig.Value else nil
end

local function turnButton(props: {
	Position: UDim2,
	OnClick: () -> (),
})
	return e("ImageButton", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ImageTransparency = 1,
		Position = props.Position,
		Size = UDim2.fromScale(0.5, 1),
		[React.Event.Activated] = props.OnClick,
	})
end
-- Class
-- the two mannequins on the one set, seen from a camera that stays put: whichever identity is edited stands in front
return function(_: Properties): React.ReactNode
	local topInset = React.useContext(AppTopInsetContext)
	local isHeroFocus = React.useContext(IsHeroFocusContext)
	local character = React.useContext(CharacterContext)
	local previewCharacter = React.useContext(PreviewCharacterContext)
	local displayedCharacter = previewCharacter or character
	local mainAppearance = displayedCharacter.Identities.Main.Appearance
	local secretIdentity = displayedCharacter.Identities.Secret
	local secretAppearance = if secretIdentity then secretIdentity.Appearance else EMPTY_APPEARANCE

	local viewportRef: { current: ViewportFrame? } = React.useRef(nil :: ViewportFrame?)
	local worldModelRef: { current: WorldModel? } = React.useRef(nil :: WorldModel?)
	local cameraRef: { current: Camera? } = React.useRef(nil :: Camera?)
	local turnDeg, setTurnDeg = React.useState(0)
	-- how far the pair has turned so far, it trails the turn that was asked for
	local shownDegRef = React.useRef(0)
	local isTurningRef = React.useRef(false)
	local heroScene = useScene(HeroSceneTemplate)
	local secretScene = useScene(SecretSceneTemplate)
	-- ahead of the appearances: a rig is in the world by the time it gets dressed
	useWorldModel(heroScene, worldModelRef)
	useWorldModel(secretScene, worldModelRef)
	useAppearance(heroScene, mainAppearance)
	useAppearance(secretScene, secretAppearance)

	local heroRig, secretRig = getRig(heroScene), getRig(secretScene)
	-- the set has one spot in front + one behind it, the scene of each identity brings one of them
	local frontAnchor = if heroScene and heroScene.IsAlive then heroScene.RigAnchor else nil
	local backAnchor = if secretScene and secretScene.IsAlive then secretScene.RigAnchor else nil
	local cameraMount = if heroScene and heroScene.IsAlive then heroScene.CameraMount else nil

	React.useEffect(function()
		local viewport, camera = viewportRef.current, cameraRef.current
		if viewport and camera then
			viewport.CurrentCamera = camera
		end
		return function() end
	end, {})

	React.useEffect(function()
		local camera = cameraRef.current
		if camera and cameraMount and frontAnchor then
			camera.CFrame = CFrame.lookAt(
				cameraMount.Position,
				frontAnchor.CFrame:PointToWorldSpace(CONSTANTS.CAMERA_TARGET_OFFSET)
			)
		end
		return function() end
	end, { cameraMount :: any, frontAnchor })

	React.useEffect(function()
		local function place()
			local turn = CFrame.Angles(0, math.rad(shownDegRef.current), 0)
			local heroAnchor = if isHeroFocus then frontAnchor else backAnchor
			local secretAnchor = if isHeroFocus then backAnchor else frontAnchor
			if heroRig and heroAnchor then
				RigUtil.moveTo(heroRig, heroAnchor.CFrame * turn)
			end
			if secretRig and secretAnchor then
				RigUtil.moveTo(secretRig, secretAnchor.CFrame * turn)
			end
		end
		-- the two swap spots at once, only a turn is eased
		place()
		if shownDegRef.current == turnDeg then
			isTurningRef.current = false
			return function() end
		end
		isTurningRef.current = true
		local connection: RBXScriptConnection
		connection = RunService.RenderStepped:Connect(function(dt: number)
			local shownDeg = shownDegRef.current
			local step = math.min(math.abs(turnDeg - shownDeg), TURN_SPEED_DEG * dt)
			shownDegRef.current = shownDeg + math.sign(turnDeg - shownDeg) * step
			place()
			if shownDegRef.current == turnDeg then
				isTurningRef.current = false
				connection:Disconnect()
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { turnDeg :: any, isHeroFocus, heroRig, secretRig, frontAnchor, backAnchor })

	-- a press isn't taken while the pair is still turning
	local function turn(direction: number)
		if not isTurningRef.current then
			isTurningRef.current = true
			setTurnDeg(turnDeg + direction * CONSTANTS.TURN_STEP_DEG)
		end
	end

	return e(React.Fragment, {}, {
		ViewportFrame = e(
			"ViewportFrame",
			{
				ZIndex = 0,
				Active = false,
				BackgroundTransparency = 1,
				ref = viewportRef,
				Position = UDim2.fromOffset(0, -topInset),
				Size = UDim2.new(1, 0, 1, topInset),
			} :: RobloxComponents.ViewportFrameProperties,
			{
				Camera = e("Camera", {
					ref = cameraRef,
				}),
				WorldModel = e("WorldModel", {
					ref = worldModelRef,
				}),
			}
		),
		-- nothing shows where the pair is turned, the halves of the stage are the buttons
		Turn = e("Frame", {
			AnchorPoint = CONSTANTS.STAGE_ANCHOR_POINT,
			BackgroundTransparency = 1,
			Position = CONSTANTS.STAGE_POSITION,
			Size = CONSTANTS.STAGE_SIZE,
		}, {
			Left = e(turnButton, {
				Position = UDim2.fromScale(0.25, 0.5),
				OnClick = function()
					turn(-1)
				end,
			}),
			Right = e(turnButton, {
				Position = UDim2.fromScale(0.75, 0.5),
				OnClick = function()
					turn(1)
				end,
			}),
		}),
	})
end
