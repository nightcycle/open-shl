--!strict
--!native
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
-- Components
-- Hooks
local useAppearance = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useAppearance")
local useScene = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useScene")
-- Contexts
local AppTopInsetContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/TopInset")
local CharacterContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character")
local PreviewCharacterContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Preview")
-- Types
export type Properties = {}
-- Constants
local ROTATION_INC_DEG = 45
-- Variables
-- References
local SceneTemplate = IndexUtil.waitForPath("game/ReplicatedStorage/lib/scene/artifact-editor") :: Folder
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local topInset = React.useContext(AppTopInsetContext)
	local character = React.useContext(CharacterContext)
	local previewCharacter = React.useContext(PreviewCharacterContext)
	local appearance = (previewCharacter or character).Identities.Main.Appearance

	local viewportRef: { current: ViewportFrame? } = React.useRef(nil :: ViewportFrame?)
	local rotationDeg, setRotationDeg = React.useState(0)
	local artifactScene, refreshScene = useScene(SceneTemplate)

	React.useEffect(function()
		local viewport = viewportRef.current
		if not viewport or not artifactScene then
			return function() end
		end
		local camera = Instance.new("Camera")
		local worldModel = Instance.new("WorldModel")
		local cleanUp: () -> () = function() end
		task.spawn(function()
			assert(artifactScene.IsAlive, `bad scene`)
			artifactScene.Instance.Parent = worldModel
			worldModel.Parent = viewport
			viewport.CurrentCamera = camera
			camera.CFrame = artifactScene.CameraMount.CFrame
			camera.Parent = viewport
		end)
		return function()
			cleanUp()
			worldModel:Destroy()
			camera:Destroy()
			refreshScene()
		end
	end, { viewportRef.current :: any, artifactScene })

	React.useEffect(function()
		if artifactScene and artifactScene.IsAlive and artifactScene.Rig.IsDone then
			task.spawn(function()
				RigUtil.moveTo(
					artifactScene.Rig.Value,
					artifactScene.RigAnchor.CFrame * CFrame.Angles(0, math.rad(rotationDeg), 0)
				)
			end)
		end
	end, { rotationDeg :: any, artifactScene and artifactScene.IsAlive and artifactScene.Rig.IsDone })

	useAppearance(artifactScene, appearance)

	return e(React.Fragment, {}, {
		ViewportFrame = e(
			"ViewportFrame",
			{
				ZIndex = 0,
				Active = false,
				BackgroundTransparency = 1,
				ref = viewportRef,
				-- the menu starts under the top bar, the viewport reaches back up over it
				Position = UDim2.fromOffset(0, -topInset),
				Size = UDim2.new(1, 0, 1, topInset),
			} :: RobloxComponents.ViewportFrameProperties
		),

		TurnCharacter = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.225, 0.05),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}, {
			Right = artifactScene and artifactScene.IsAlive and artifactScene.Rig.IsDone and e("TextButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(),
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = ">",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					setRotationDeg(rotationDeg + ROTATION_INC_DEG)
				end,
			}),

			Left = artifactScene and artifactScene.IsAlive and artifactScene.Rig.IsDone and e("TextButton", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.new(),
				BackgroundTransparency = 0.5,
				BorderColor3 = Color3.new(),
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Modal = true,
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromScale(0.2, 0.2),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = "<",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
				TextStrokeColor3 = Color3.new(1, 1, 1),
				[React.Event.Activated] = function()
					setRotationDeg(rotationDeg - ROTATION_INC_DEG)
				end,
			}),
		}),
	})
end
