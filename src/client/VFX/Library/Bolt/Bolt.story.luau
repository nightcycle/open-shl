--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- shot from the right hand of the user at the target, what it runs into is printed. without the fire it's the part
-- itself that's seen
return VFXStory.newEventStory({
	Distance = UILabs.Slider(30, 4, 60, 1),
	Speed = UILabs.Slider(80, 5, 300, 5),
	Lifetime = UILabs.Slider(10, 0.5, 20, 0.5),
	Width = UILabs.Slider(0.4, 0.1, 4, 0.1),
	Height = UILabs.Slider(0.4, 0.1, 4, 0.1),
	Length = UILabs.Slider(4, 0.5, 16, 0.5),
	Color = UILabs.Datatype.Color3(BrickColor.new("Bright orange").Color),
	HasFire = UILabs.Boolean(true),
	FireSize = UILabs.Slider(7, 2, 30, 0.5),
}, function(stage: VFXStory.Stage, controls)
	local hand = stage.User:FindFirstChild("RightHand")
	local targetRoot = stage.Target.PrimaryPart
	if not hand or not hand:IsA("BasePart") or not targetRoot then
		return
	end
	local origin = hand.Position
	stage.ClientScope.fire(ClientVFXDefinition.Bolt, {
		Origin = origin,
		Direction = targetRoot.Position - origin,
		Speed = controls.Speed,
		Lifetime = controls.Lifetime,
		Size = Vector3.new(controls.Width, controls.Height, controls.Length),
		Color = controls.Color,
		FireSize = if controls.HasFire then controls.FireSize else nil,
		OnHit = function(result: RaycastResult)
			print(`hit: {result.Instance:GetFullName()}`)
		end,
	})
end)
