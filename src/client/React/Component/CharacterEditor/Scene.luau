--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
local AppearanceUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance")
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
-- Components
local ViewportFrame = require("@game/ReplicatedStorage/Generated/React/Component/ViewportFrame")
-- Hooks
local useArtifactScene = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useArtifactScene")
-- Contexts
local CharacterAppearanceContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/Appearance")
local CharacterPreviewAppearanceContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Character/PreviewAppearance")
-- Types
export type Properties = {}
-- Constants
local ROTATION_INC_DEG = 45
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local appearance: CharacterAppearanceContext.Appearance = React.useContext(CharacterAppearanceContext)
	local previewAppearance: CharacterAppearanceContext.Appearance? =
		React.useContext(CharacterPreviewAppearanceContext)
	if previewAppearance then
		appearance = previewAppearance
	end

	local viewportRef: { current: ViewportFrame? } = React.useRef(nil :: ViewportFrame?)
	local rotationDeg, setRotationDeg = React.useState(0)
	local artifactScene, refreshScene = useArtifactScene()

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
	end, { viewportRef.current :: any })

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

	React.useEffect(function()
		if appearance and artifactScene and artifactScene.IsAlive and artifactScene.Rig.IsDone then
			local isDead = false
			task.spawn(function()
				print(`applying appearance: isDead={isDead}`)
				local resF: TypeUnionLib.Future<TypeUnionLib.Result<true, { string }>> = TypeUnionLib.Future.awaitUntil(
					AppearanceUtil.apply(artifactScene.Rig.Value, appearance),
					function()
						return isDead
					end
				)
				if resF.IsDone then
					if resF.Value.IsErr then
						for i, v in resF.Value.Value do
							warn(`appearance err: {v}`)
						end
					else
						print(`successfully applied appearance`)
					end
				end
			end)
			return function()
				isDead = true
			end
		end
		return function() end
	end, { appearance :: any, artifactScene and artifactScene.IsAlive and artifactScene.Rig.IsDone })

	return e(React.Fragment, {}, {
		ViewportFrame = e(
			"ViewportFrame",
			{
				ZIndex = 0,
				Active = false,
				BackgroundTransparency = 1,
				ref = viewportRef,
				Size = UDim2.fromScale(1, 1),
			} :: ViewportFrame.Properties
		),
		TurnChar = e("Frame", {
			BackgroundTransparency = 1,
			Position = UDim2.fromScale(0.325, 1.65),
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
