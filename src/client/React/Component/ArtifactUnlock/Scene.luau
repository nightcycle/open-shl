--!strict
--!native
-- Services
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local AppearanceConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance")
local ItemConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Character/Identity/Appearance/Item")
local ItemUtil = require("@game/ReplicatedStorage/Shared/Util/Appearance/Item")
-- Components
-- Hooks
local useScene = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useScene")
-- Contexts
local AppTopInsetContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/TopInset")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type ItemDefinition = AppearanceType.ItemDefinition
type Door = {
	Model: Model,
	ClosedPivot: CFrame,
	Travel: Vector3,
}
export type Properties = {
	ItemDefinition: ItemDefinition,
	IsOpen: boolean,
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ArtifactUnlock/CONSTANTS")
local EMPTY_APPEARANCE = AppearanceConstructor.new()
-- Variables
-- References
local SceneTemplate = IndexUtil.waitForPath("game/ReplicatedStorage/lib/scene/artifact-vault") :: Folder
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local topInset = React.useContext(AppTopInsetContext)
	local definitionId = props.ItemDefinition.Id
	local viewportRef: { current: ViewportFrame? } = React.useRef(nil :: ViewportFrame?)
	local currentCamera: Camera?, setCurrentCamera: (Camera?) -> () = React.useState(nil :: Camera?)
	local vaultScene, refreshScene = useScene(SceneTemplate)
	local rig = if vaultScene and vaultScene.IsAlive and vaultScene.Rig.IsDone then vaultScene.Rig.Value else nil

	React.useEffect(function()
		local viewport = viewportRef.current
		if not viewport or not vaultScene then
			return function() end
		end
		local camera = Instance.new("Camera")
		local worldModel = Instance.new("WorldModel")
		task.spawn(function()
			assert(vaultScene.IsAlive, `bad scene`)
			vaultScene.Instance.Parent = worldModel
			worldModel.Parent = viewport
			viewport.CurrentCamera = camera
			camera.CFrame = vaultScene.CameraMount.CFrame
			camera.Parent = viewport
		end)
		return function()
			worldModel:Destroy()
			camera:Destroy()
			refreshScene()
		end
	end, { viewportRef.current :: any, vaultScene })

	React.useEffect(function()
		if not rig then
			return function() end
		end
		-- the dummy on the pedestal isn't seen, only the artifact it wears shows
		for _, v in rig:GetDescendants() do
			if v:IsA("BasePart") then
				v.Transparency = 1
			end
			-- a decal still renders on a part that can't be seen
			if v:IsA("Decal") then
				v.Transparency = 1
			end
		end
		-- a vault with nothing in it still gets to name the artifact
		local success, res = pcall(ItemUtil.apply, rig, EMPTY_APPEARANCE, ItemConstructor.new(definitionId))
		if not success then
			warn(`artifact "{definitionId}" threw: {res}`)
		elseif res.IsErr then
			warn(`artifact err: {res.Value}`)
		end
		return function()
			local item = rig:FindFirstChild(definitionId)
			if item then
				item:Destroy()
			end
		end
	end, { rig :: any, definitionId })

	-- read while the doors of a new scene are still shut, where they end up is counted from there
	local doors = React.useMemo(function(): { Door }
		local out: { Door } = {}
		if not vaultScene or not vaultScene.IsAlive then
			return out
		end
		for name, travel in CONSTANTS.DOOR_TRAVELS do
			local model = IndexUtil.findFirstLocalPath(vaultScene.Instance, `Door/{name}`)
			if model and model:IsA("Model") then
				table.insert(out, {
					Model = model,
					ClosedPivot = model:GetPivot(),
					Travel = travel,
				})
			else
				warn(`the vault has no door "{name}"`)
			end
		end
		return out
	end, { vaultScene })

	do
		local isOpenRef = React.useRef(props.IsOpen)
		isOpenRef.current = props.IsOpen
		-- how far the vault is open, from 0 to 1. it outlives the scene, a new one picks up where the last one was
		local openAlphaRef = React.useRef(0)
		React.useEffect(function()
			if not currentCamera or not vaultScene or not vaultScene.IsAlive then
				return function() end
			end
			local closedCameraCFrame = vaultScene.CameraMount.CFrame
			local openCameraMount = vaultScene.Instance:FindFirstChild(CONSTANTS.OPEN_CAMERA_NAME)
			local openCameraCFrame = if openCameraMount and openCameraMount:IsA("BasePart")
				then openCameraMount.CFrame
				else closedCameraCFrame

			local function apply(alpha: number)
				for _, door in doors do
					door.Model:PivotTo(door.ClosedPivot + door.Travel * alpha)
				end
				-- the doors slide at an even pace, the camera eases in
				currentCamera.CFrame = closedCameraCFrame:Lerp(
					openCameraCFrame,
					TweenService:GetValue(alpha, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
				)
			end
			apply(openAlphaRef.current)

			local connection = RunService.RenderStepped:Connect(function(dt: number)
				local goal = isOpenRef.current and 1 or 0
				local alpha = openAlphaRef.current
				if alpha == goal then
					return
				end
				local step = dt / CONSTANTS.OPEN_DURATION
				alpha = if goal > alpha then math.min(alpha + step, goal) else math.max(alpha - step, goal)
				openAlphaRef.current = alpha
				apply(alpha)
			end)

			return function()
				connection:Disconnect()
			end
		end, { currentCamera :: any, vaultScene, doors })
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
				[React.Change.CurrentCamera] = function(rbx: ViewportFrame)
					setCurrentCamera(rbx.CurrentCamera)
				end,
			} :: RobloxComponents.ViewportFrameProperties
		),
	})
end
