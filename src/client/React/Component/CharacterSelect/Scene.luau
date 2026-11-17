--!strict
--!native
-- Services
local RunService = game:GetService("RunService")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
local Booth = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterSelect/Booth")
-- Hooks
-- Contexts
local AppTopInsetContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/TopInset")
-- Types
export type Properties = {
	Index: number,
}
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterSelect/CONSTANTS")
-- the booths kept on either side of the centered one, the pair that's out of view is dressed by the time it slides in
local NEIGHBOR_COUNT = 2
-- Variables
-- References
local CameraMount = IndexUtil.waitForPath("game/ReplicatedStorage/lib/scene/character-select/Cam") :: BasePart
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties): React.ReactNode
	local topInset = React.useContext(AppTopInsetContext)
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

	-- where the camera is along the row, counted in booths. it trails the index at a steady pace
	local positionRef = React.useRef(props.Index)
	local indexRef = React.useRef(props.Index)
	indexRef.current = props.Index
	React.useEffect(function()
		if not camera then
			return function() end
		end
		local function update(deltaTime: number)
			local distance = indexRef.current - positionRef.current
			local step = deltaTime / CONSTANTS.SLIDE_DURATION
			if math.abs(distance) <= step then
				positionRef.current = indexRef.current
			else
				positionRef.current += math.sign(distance) * step
			end
			camera.CFrame = CameraMount.CFrame + Vector3.new(CONSTANTS.BOOTH_WIDTH * positionRef.current, 0, 0)
		end
		update(0)
		local connection = RunService.RenderStepped:Connect(update)
		return function()
			connection:Disconnect()
		end
	end, { camera })

	local booths: { [string]: React.ReactNode } = {}
	if worldModel then
		for index = props.Index - NEIGHBOR_COUNT, props.Index + NEIGHBOR_COUNT do
			-- keyed by where it stands, so a booth that's still in the row after a turn is left as it is
			booths[`Booth-{index}`] = e(
				Booth,
				{
					Index = index,
					WorldModel = worldModel,
				} :: Booth.Properties
			)
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
			} :: RobloxComponents.ViewportFrameProperties
		),
		Booths = e(React.Fragment, {}, booths),
	})
end
