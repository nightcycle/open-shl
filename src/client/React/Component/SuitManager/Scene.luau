--!strict
--!native
-- Services
local RunService = game:GetService("RunService")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
-- Modules
local AppearanceUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance")
local RigUtil = require("@game/ReplicatedStorage/Shared/Util/Rig")
-- Components
-- Hooks
local useScene = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useScene")
-- Contexts
local AppTopInsetContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/TopInset")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
export type Appearance = AppearanceType.Appearance
export type Properties = {
	-- whose look the mannequin wears, it stands bare until there's one
	Appearance: Appearance?,
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/SuitManager/CONSTANTS")
-- a body that was never sized is the plain one
local DEFAULT_HEIGHT = 1
-- Variables
-- References
local SceneTemplate = IndexUtil.waitForPath("game/ReplicatedStorage/lib/scene/character-select") :: Folder
local CameraMount = IndexUtil.waitForPath("game/ReplicatedStorage/lib/scene/character-select/Cam") :: BasePart
local RigAnchor = IndexUtil.waitForPath("game/ReplicatedStorage/lib/scene/character-select/RigAnchor") :: BasePart
-- Private Functions
local e = React.createElement

-- from where + at what a body of that height is looked at
local function getFraming(height: number): CFrame
	local growth = height - DEFAULT_HEIGHT
	local position = (CameraMount.CFrame * CFrame.new(0, 0, CONSTANTS.CAMERA_RETREAT * growth)).Position
	local focus = RigAnchor.Position + Vector3.new(0, CONSTANTS.FOCUS_HEIGHT + CONSTANTS.FOCUS_RISE * growth, 0)
	return CFrame.lookAt(position, focus)
end
-- Class
-- one stage with one mannequin on it, whoever is picked is who it's dressed as
return function(props: Properties): React.ReactNode
	local topInset = React.useContext(AppTopInsetContext)
	local appearance = props.Appearance
	local height = if appearance and appearance.Scale then appearance.Scale.Height else DEFAULT_HEIGHT

	local viewportRef: { current: ViewportFrame? } = React.useRef(nil :: ViewportFrame?)
	local camera: Camera?, setCamera: (Camera?) -> () = React.useState(nil :: Camera?)
	local worldModel: WorldModel?, setWorldModel: (WorldModel?) -> () = React.useState(nil :: WorldModel?)
	React.useEffect(function()
		local viewport = viewportRef.current
		if not viewport then
			return function() end
		end
		local newCamera = Instance.new("Camera")
		local newWorldModel = Instance.new("WorldModel")
		newCamera.CFrame = CameraMount.CFrame
		-- a stage says how narrow the lens is that it's looked at through, one that doesn't is seen through a plain one
		local fieldOfView = CameraMount:GetAttribute("FieldOfView")
		if type(fieldOfView) == "number" then
			newCamera.FieldOfView = fieldOfView
		end
		newWorldModel.Parent = viewport
		newCamera.Parent = viewport
		viewport.CurrentCamera = newCamera
		setCamera(newCamera)
		setWorldModel(newWorldModel)
		return function()
			newWorldModel:Destroy()
			newCamera:Destroy()
		end
	end, {})

	-- the camera starts out where the stage has it, then turns to whoever stands there
	React.useEffect(function()
		if not camera then
			return function() end
		end
		local from = camera.CFrame
		local to = getFraming(height)
		local startClock = os.clock()
		local connection: RBXScriptConnection
		connection = RunService.RenderStepped:Connect(function()
			local alpha = math.min((os.clock() - startClock) / CONSTANTS.CAMERA_DURATION, 1)
			camera.CFrame = from:Lerp(to, alpha)
			if alpha == 1 then
				connection:Disconnect()
			end
		end)
		return function()
			connection:Disconnect()
		end
	end, { camera :: any, height })

	-- the bare stage stands in until the rig of the scene was made, so there's no hole where the room is
	local standIn = React.useState(function(): Folder
		return SceneTemplate:Clone()
	end)
	React.useEffect(function()
		return function()
			standIn:Destroy()
		end
	end, {})

	local scene = useScene(SceneTemplate)
	React.useEffect(function()
		if scene and scene.IsAlive then
			scene.Instance.Parent = worldModel
			standIn.Parent = nil
		else
			standIn.Parent = worldModel
		end
		return function() end
	end, { scene :: any, worldModel, standIn })

	-- after the scene went under the world model: a rig is in the world by the time it gets dressed. a body of another
	-- size stands at another height, so the mannequin is put back on its spot once it wears the look
	local rig = if scene and scene.IsAlive and scene.Rig.IsDone then scene.Rig.Value else nil
	local rigAnchor = if scene and scene.IsAlive then scene.RigAnchor else nil
	React.useEffect(function()
		if not rig or not rigAnchor or not appearance then
			return function() end
		end
		local isDead = false
		task.spawn(function()
			local resF: TypeUnionLib.Future<TypeUnionLib.Result<true, { string }>> = Future.awaitUntil(
				AppearanceUtil.apply(rig, appearance),
				function()
					return isDead
				end
			)
			if not resF.IsDone then
				return
			end
			if resF.Value.IsErr then
				for _, message in resF.Value.Value do
					warn(`appearance err: {message}`)
				end
			end
			RigUtil.moveTo(rig, rigAnchor.CFrame)
		end)
		return function()
			isDead = true
		end
	end, { appearance :: any, rig, rigAnchor })

	return e(
		"ViewportFrame",
		{
			ZIndex = 0,
			Active = false,
			BackgroundTransparency = 1,
			ref = viewportRef,
			Position = UDim2.fromOffset(0, -topInset),
			Size = UDim2.new(1, 0, 1, topInset),
		} :: RobloxComponents.ViewportFrameProperties
	)
end
