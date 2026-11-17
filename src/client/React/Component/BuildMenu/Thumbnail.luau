--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local BaseUtil = require("@game/ReplicatedStorage/Shared/Util/Base")
-- Components
-- Hooks
-- Contexts
-- Types
export type Properties = RobloxComponents.ViewportFrameProperties & {
	FurnitureId: string,
}
-- Constants
-- the camera the thumbnail of a model was shot through, it's still in every one of them
local THUMBNAIL_CAMERA_NAME = "ThumbnailCamera"
-- the way the camera looks at a model that came without one
local DEFAULT_LOOK = Vector3.new(-1, -0.5, -1).Unit
local FIELD_OF_VIEW = 70
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- some of the models were moved after they were shot, so only the angle of the camera is kept
local function getCameraCFrame(model: Model): CFrame
	local bounds, size = model:GetBoundingBox()
	local thumbnailCamera = model:FindFirstChild(THUMBNAIL_CAMERA_NAME)
	local look = if thumbnailCamera and thumbnailCamera:IsA("Camera")
		then thumbnailCamera.CFrame.LookVector
		else DEFAULT_LOOK
	local distance = size.Magnitude / 2 / math.sin(math.rad(FIELD_OF_VIEW / 2))
	return CFrame.lookAt(bounds.Position - look * distance, bounds.Position)
end
-- Class
return function(props: Properties)
	local viewportRef: { current: ViewportFrame? } = React.useRef(nil :: ViewportFrame?)
	React.useEffect(function()
		local viewport = viewportRef.current
		if not viewport then
			return function() end
		end
		local modelRes = BaseUtil.newModel(props.FurnitureId)
		if modelRes.IsErr then
			warn(`thumbnail err: {modelRes.Value}`)
			return function() end
		end
		local model = modelRes.Value
		for _, desc in model:GetDescendants() do
			-- the hum of a reactor would play for as long as its card is up
			if desc:IsA("Sound") then
				desc:Destroy()
			end
		end
		local camera = Instance.new("Camera")
		camera.FieldOfView = FIELD_OF_VIEW
		camera.CFrame = getCameraCFrame(model)
		camera.Parent = viewport
		model.Parent = viewport
		viewport.CurrentCamera = camera
		return function()
			model:Destroy()
			camera:Destroy()
		end
	end, { props.FurnitureId })

	return e(RobloxComponents.ViewportFrame(
		{
			ref = viewportRef,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.6,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
		} :: RobloxComponents.ViewportFrameProperties,
		props
	))
end
