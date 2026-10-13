--!strict
--!native
local RunService = game:GetService("RunService")
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local React = require("@game/ReplicatedStorage/Packages/React")
local Spring = require("@game/ReplicatedStorage/Packages/Spring")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
local AppearanceConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance")
local AppearanceUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance")
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
-- Components
local ViewportFrame = require("@game/ReplicatedStorage/Generated/React/Component/ViewportFrame")
-- Hooks
local useScene = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useScene")
-- Contexts
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local IsHeroFocusContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/CharacterEditor/IsHeroFocus")
local PreviewCharacterContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Preview")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
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
local function useAppearance(scene: useScene.Scene?, appearance: AppearanceType.Appearance)
	local rig = if scene and scene.IsAlive and scene.Rig.IsDone then scene.Rig.Value else nil
	React.useEffect(function()
		if not rig then
			return function() end
		end
		local isDead = false
		task.spawn(function()
			local resF: TypeUnionLib.Future<TypeUnionLib.Result<true, { string }>> = TypeUnionLib.Future.awaitUntil(
				AppearanceUtil.apply(rig, appearance),
				function()
					return isDead
				end
			)
			if resF.IsDone and resF.Value.IsErr then
				for _, message in resF.Value.Value do
					warn(`appearance err: {message}`)
				end
			end
		end)
		return function()
			isDead = true
		end
	end, { appearance :: any, rig })
end
-- Class
return function(props: Properties): React.ReactNode
	local isHeroFocus = React.useContext(IsHeroFocusContext)
	local character = React.useContext(CharacterContext)
	local previewCharacter = React.useContext(PreviewCharacterContext)
	local displayedCharacter = previewCharacter or character
	local mainAppearance = displayedCharacter.Identities.Main.Appearance
	local secretIdentity = displayedCharacter.Identities.Secret
	local secretAppearance = if secretIdentity then secretIdentity.Appearance else EMPTY_APPEARANCE

	local viewportRef: { current: ViewportFrame? } = React.useRef(nil :: ViewportFrame?)
	local heroRotationDeg, setHeroRotationDeg = React.useState(0)
	local secretRotationDeg, setSecretRotationDeg = React.useState(0)
	local heroScene, refreshHeroScene = useScene(HeroSceneTemplate)
	local secretScene, refreshSecretScene = useScene(SecretSceneTemplate)
	useAppearance(heroScene, mainAppearance)
	useAppearance(secretScene, secretAppearance)

	React.useEffect(function()
		local viewport = viewportRef.current
		if not viewport or not heroScene or not secretScene or not heroScene.IsAlive or not secretScene.IsAlive then
			return function() end
		end
		local camera = Instance.new("Camera")
		local worldModel = Instance.new("WorldModel")
		local cleanUp: () -> () = function() end
		task.spawn(function()
			heroScene.Instance.Parent = worldModel
			secretScene.Instance.Parent = worldModel
			worldModel.Parent = viewport
			viewport.CurrentCamera = camera
			camera.CFrame = isHeroFocus and heroScene.CameraMount.CFrame or secretScene.CameraMount.CFrame
			camera.Parent = viewport
		end)
		return function()
			cleanUp()
			worldModel:Destroy()
			camera:Destroy()
			refreshHeroScene()
			refreshSecretScene()
		end
	end, { viewportRef.current :: any, heroScene, secretScene })

	local currentCamera: Camera?, setCurrentCamera: (Camera?) -> () = React.useState(nil :: Camera?)
	do
		local isHeroFocusRef = React.useRef(isHeroFocus)
		isHeroFocusRef.current = isHeroFocus
		local springRef = React.useRef(Spring.new(1, 0.8, isHeroFocusRef.current and 0 or 1))
		React.useEffect(function()
			if
				not currentCamera
				or not heroScene
				or not secretScene
				or not heroScene.IsAlive
				or not secretScene.IsAlive
			then
				return function() end
			end

			local connection = RunService.RenderStepped:Connect(function(dt: number)
				local spring = springRef.current
				if isHeroFocusRef.current then
					spring:Set(0)
				else
					spring:Set(1)
				end
				spring:Step(dt)
				currentCamera.CFrame = heroScene.CameraMount.CFrame:Lerp(secretScene.CameraMount.CFrame, spring:Get())
			end)

			return function()
				connection:Disconnect()
			end
		end, {
			currentCamera :: any,
			secretScene and secretScene.IsAlive and secretScene.CameraMount,
			heroScene and heroScene.IsAlive and heroScene.CameraMount,
		})
	end

	React.useEffect(function()
		if heroScene and heroScene.IsAlive and heroScene.Rig.IsDone then
			task.spawn(function()
				RigUtil.moveTo(
					heroScene.Rig.Value,
					heroScene.RigAnchor.CFrame * CFrame.Angles(0, math.rad(heroRotationDeg), 0)
				)
			end)
		end
	end, { heroRotationDeg :: any, heroScene and heroScene.IsAlive and heroScene.Rig.IsDone })

	React.useEffect(function()
		if secretScene and secretScene.IsAlive and secretScene.Rig.IsDone then
			task.spawn(function()
				RigUtil.moveTo(
					secretScene.Rig.Value,
					secretScene.RigAnchor.CFrame * CFrame.Angles(0, math.rad(secretRotationDeg), 0)
				)
			end)
		end
	end, { secretRotationDeg :: any, secretScene and secretScene.IsAlive and secretScene.Rig.IsDone })

	return e(React.Fragment, {}, {
		ViewportFrame = e(
			"ViewportFrame",
			{
				ZIndex = 0,
				Active = false,
				BackgroundTransparency = 1,
				ref = viewportRef,
				Size = UDim2.fromScale(1, 1),
				[React.Change.CurrentCamera] = function(rbx: ViewportFrame)
					setCurrentCamera(rbx.CurrentCamera)
				end,
			} :: ViewportFrame.Properties
		),
		TurnChar = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.325, 0.5),
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
					if isHeroFocus then
						setHeroRotationDeg(heroRotationDeg + ROTATION_INC_DEG)
					else
						setSecretRotationDeg(secretRotationDeg + ROTATION_INC_DEG)
					end
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
					if isHeroFocus then
						setHeroRotationDeg(heroRotationDeg - ROTATION_INC_DEG)
					else
						setSecretRotationDeg(secretRotationDeg - ROTATION_INC_DEG)
					end
				end,
			}),
		}),
	})
end
