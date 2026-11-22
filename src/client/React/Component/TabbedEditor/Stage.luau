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
local useFraming = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useFraming")
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
-- a body that was never sized is the plain one
local DEFAULT_HEIGHT = 1
-- the stage is come to with the camera where it belongs, it only moves for a body that's sized under it
local FRAMING: useFraming.Rule = table.freeze({
	TargetOffset = CONSTANTS.CAMERA_TARGET_OFFSET,
	Follow = CONSTANTS.CAMERA_FOLLOW,
	Duration = CONSTANTS.CAMERA_DURATION,
})
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
-- the two mannequins on the one set, seen from a camera that only gives way to how tall they are: whichever identity
-- is edited stands in front
return function(_: Properties): React.ReactNode
	local topInset = React.useContext(AppTopInsetContext)
	local isHeroFocus = React.useContext(IsHeroFocusContext)
	local character = React.useContext(CharacterContext)
	local previewCharacter = React.useContext(PreviewCharacterContext)
	local displayedCharacter = previewCharacter or character
	local mainAppearance = displayedCharacter.Identities.Main.Appearance
	local secretIdentity = displayedCharacter.Identities.Secret
	local secretAppearance = if secretIdentity then secretIdentity.Appearance else EMPTY_APPEARANCE
	-- the two are one body, the camera goes by whoever is in front all the same
	local frontScale = if isHeroFocus then mainAppearance.Scale else secretAppearance.Scale
	local height = if frontScale then frontScale.Height else DEFAULT_HEIGHT

	local viewportRef: { current: ViewportFrame? } = React.useRef(nil :: ViewportFrame?)
	local worldModelRef: { current: WorldModel? } = React.useRef(nil :: WorldModel?)
	local cameraRef: { current: Camera? } = React.useRef(nil :: Camera?)
	-- how far the pair was asked to turn + how far it has so far, which trails behind
	local turnDegRef = React.useRef(0)
	local shownDegRef = React.useRef(0)
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

	useFraming(cameraRef, cameraMount, frontAnchor, height, FRAMING)

	-- a rig that's dressed in another size is left standing where its old body stood, so the pair is put on its spots
	-- every frame rather than only when one of them moves
	React.useEffect(function()
		local connection = RunService.RenderStepped:Connect(function(dt: number)
			local shownDeg, turnDeg = shownDegRef.current, turnDegRef.current
			if shownDeg ~= turnDeg then
				local step = math.min(math.abs(turnDeg - shownDeg), TURN_SPEED_DEG * dt)
				shownDeg += math.sign(turnDeg - shownDeg) * step
				shownDegRef.current = shownDeg
			end
			-- the two swap spots at once, only a turn is eased
			local turn = CFrame.Angles(0, math.rad(shownDeg), 0)
			local heroAnchor = if isHeroFocus then frontAnchor else backAnchor
			local secretAnchor = if isHeroFocus then backAnchor else frontAnchor
			if heroRig and heroAnchor then
				RigUtil.moveTo(heroRig, heroAnchor.CFrame * turn)
			end
			if secretRig and secretAnchor then
				RigUtil.moveTo(secretRig, secretAnchor.CFrame * turn)
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { isHeroFocus :: any, heroRig, secretRig, frontAnchor, backAnchor })

	-- a press isn't taken while the pair is still turning
	local function turn(direction: number)
		if shownDegRef.current == turnDegRef.current then
			turnDegRef.current += direction * CONSTANTS.TURN_STEP_DEG
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
