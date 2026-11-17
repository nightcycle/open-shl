--!strict
--!native
-- Services
local RunService = game:GetService("RunService")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
local Spring = require("@game/ReplicatedStorage/Packages/Spring")
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
local ROTATION_INC_DEG = 45
local EMPTY_APPEARANCE = AppearanceConstructor.new()
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
local function useRotation(scene: useScene.Scene?, rotationDeg: number)
	React.useEffect(function()
		if scene and scene.IsAlive and scene.Rig.IsDone then
			local rig, rigAnchor = scene.Rig.Value, scene.RigAnchor
			task.spawn(function()
				RigUtil.moveTo(rig, rigAnchor.CFrame * CFrame.Angles(0, math.rad(rotationDeg), 0))
			end)
		end
		return function() end
	end, { rotationDeg :: any, scene and scene.IsAlive and scene.Rig.IsDone })
end
-- Class
return function(props: Properties): React.ReactNode
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
	local rotationDeg, setRotationDeg = React.useState(0)
	local heroScene = useScene(HeroSceneTemplate)
	local secretScene = useScene(SecretSceneTemplate)
	-- ahead of the appearances: a rig is in the world by the time it gets dressed
	useWorldModel(heroScene, worldModelRef)
	useWorldModel(secretScene, worldModelRef)
	useAppearance(heroScene, mainAppearance)
	useAppearance(secretScene, secretAppearance)
	useRotation(heroScene, rotationDeg)
	useRotation(secretScene, rotationDeg)

	React.useEffect(function()
		local viewport, camera = viewportRef.current, cameraRef.current
		if viewport and camera then
			viewport.CurrentCamera = camera
		end
		return function() end
	end, {})

	do
		local isHeroFocusRef = React.useRef(isHeroFocus)
		isHeroFocusRef.current = isHeroFocus
		local springRef = React.useRef(Spring.new(1, 0.8, isHeroFocusRef.current and 0 or 1))
		local heroMount = if heroScene and heroScene.IsAlive then heroScene.CameraMount else nil
		local secretMount = if secretScene and secretScene.IsAlive then secretScene.CameraMount else nil
		React.useEffect(function()
			if not heroMount and not secretMount then
				return function() end
			end

			local connection = RunService.RenderStepped:Connect(function(dt: number)
				local camera = cameraRef.current
				if not camera then
					return
				end
				local spring = springRef.current
				if isHeroFocusRef.current then
					spring:Set(0)
				else
					spring:Set(1)
				end
				spring:Step(dt)
				if heroMount and secretMount then
					camera.CFrame = heroMount.CFrame:Lerp(secretMount.CFrame, spring:Get())
				else
					local mount = if isHeroFocusRef.current then heroMount else secretMount
					if mount then
						camera.CFrame = mount.CFrame
					end
				end
			end)

			return function()
				connection:Disconnect()
			end
		end, { heroMount :: any, secretMount })
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
		TurnChar = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.325, 0.45),
			Size = UDim2.fromScale(0.35, 0.05),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}, {
			Right = e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(127, 127, 127),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(),
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Position = UDim2.fromScale(0.847, 0),
				Size = UDim2.fromScale(0.143, 1),
				Text = ">",
				TextColor3 = Color3.new(),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					setRotationDeg(rotationDeg + ROTATION_INC_DEG)
				end,
			}),

			Left = e("TextButton", {
				BackgroundColor3 = Color3.fromRGB(127, 127, 127),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(),
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Size = UDim2.fromScale(0.143, 1),
				Text = "<",
				TextColor3 = Color3.new(),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					setRotationDeg(rotationDeg - ROTATION_INC_DEG)
				end,
			}),
		}),
	})
end
