--!strict
-- Services
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type Properties = ClientVFXType.SeeThrough
-- Constants
-- seconds from one turn to the next
local TURN_INTERVAL = 1 / 30
-- Variables
-- References
-- Private Functions
local function getCharacter(inst: Instance): Model?
	local model = inst:FindFirstAncestorWhichIsA("Model")
	while model do
		if model:FindFirstChildWhichIsA("Humanoid") then
			return model
		end
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return nil
end
-- Class
-- the world around the camera is looked through a layer at a time: every look goes out through a grid of spots on
-- the screen, what it finds is shown see-through on this machine alone + isn't in the way of the next look. what's
-- see-through to begin with stops a look for good, + so does the ground. whoever is found is left as they are: what
-- an avatar shows of itself is up to its own powers
return ClientVFX.state(ClientVFXDefinition.SeeThrough, function(props: Properties)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.IgnoreWater = true
	local side = math.max(math.floor(math.sqrt(props.RayCount)), 1)
	local start = props.Start or 0
	local parts: { BasePart } = {}
	local function look()
		local camera = Workspace.CurrentCamera
		if not camera then
			return
		end
		local viewportSize = camera.ViewportSize
		for column = 1, side do
			for row = 1, side do
				local x = math.ceil(column * viewportSize.X / side)
				local y = math.ceil(row * viewportSize.Y / side)
				local ray = camera:ViewportPointToRay(x, y, start)
				local result = Workspace:Raycast(ray.Origin, ray.Direction * props.Range, raycastParams)
				local found = if result then result.Instance else nil
				if not found then
					continue
				end
				local character = getCharacter(found)
				if character then
					raycastParams:AddToFilter(character)
				elseif found.Transparency == 0 and not found:IsA("Terrain") then
					-- the modifier is this machine's alone: it's in the way of nothing else that shows or hides a part
					found.LocalTransparencyModifier = props.Transparency
					table.insert(parts, found)
					raycastParams:AddToFilter(found)
				end
			end
		end
	end
	local elapsed = TURN_INTERVAL
	local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		if elapsed < TURN_INTERVAL then
			return
		end
		-- a slow machine takes its turns as they come, it never makes up for the ones it missed
		elapsed = 0
		for _ = 1, props.PassCount do
			look()
		end
	end)
	return function()
		connection:Disconnect()
		-- nothing is put back before: what was seen through once stays that way for as long as it's on
		for _, part in parts do
			part.LocalTransparencyModifier = 0
		end
	end
end)
