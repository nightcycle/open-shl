--!strict
-- Services
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.FieldOfView
-- Constants
-- Variables
-- how wide each of them that's on wants the camera to look. two at once would otherwise put back what the other one
-- left: the widest wins + the camera only goes back to how it was once the last of them let go
local Holds: { [{}]: number } = {}
-- how wide the camera looked before the first of them, nil once it's back there
local Original: number? = nil
local Current: Tween? = nil
-- References
-- Private Functions
-- sends the camera to the widest of what's held, back to how it was if nothing is
local function apply(camera: Camera, duration: number)
	local original = Original
	if not original then
		return
	end
	local widest: number? = nil
	for _, fieldOfView in Holds do
		widest = if widest then math.max(widest, fieldOfView) else fieldOfView
	end
	if Current then
		Current:Cancel()
	end
	local tween = TweenService:Create(
		camera,
		TweenInfo.new(duration, Enum.EasingStyle.Linear),
		{ FieldOfView = widest or original }
	)
	Current = tween
	if not widest then
		-- one that's cut short by the next hold leaves how it was for that one to go back to
		tween.Completed:Once(function(state: Enum.PlaybackState)
			if state == Enum.PlaybackState.Completed and Current == tween then
				Original = nil
				Current = nil
			end
		end)
	end
	tween:Play()
end
-- Class
return ClientVFX.state(ClientVFXDefinition.FieldOfView, function(props: Properties, scope: ClientScope)
	local camera = Workspace.CurrentCamera
	if not camera then
		return function() end
	end
	local key = {}
	local function hold()
		if Holds[key] then
			return
		end
		Original = Original or camera.FieldOfView
		Holds[key] = props.FieldOfView
		apply(camera, props.Duration)
	end
	local function release()
		if not Holds[key] then
			return
		end
		Holds[key] = nil
		apply(camera, props.Duration)
	end
	if not props.IsMoving then
		hold()
		return release
	end
	local character = scope.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid then
		return function() end
	end
	local function update()
		if humanoid.MoveDirection.Magnitude > 0 then
			hold()
		else
			release()
		end
	end
	update()
	local connection = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(update)
	return function()
		connection:Disconnect()
		release()
	end
end)
