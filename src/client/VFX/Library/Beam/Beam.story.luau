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
local KEY = "Story"
-- Variables
-- References
-- Private Functions
-- Class
-- it runs from the right hand of the user to the target + is gone once its time is up. put right, a second one of
-- half the length is drawn under the same key part-way through: it takes the place of the first + is gone when that
-- one would have been
return VFXStory.newEventStory({
	Distance = UILabs.Slider(30, 4, 60, 1),
	Thickness = UILabs.Slider(0.9, 0.05, 4, 0.05),
	Transparency = UILabs.Slider(0.25, 0, 1, 0.05),
	Lifetime = UILabs.Slider(0.35, 0.05, 5, 0.05),
	IsFading = UILabs.Boolean(true),
	IsPutRight = UILabs.Boolean(false),
	Color = UILabs.Datatype.Color3(Color3.new(0, 1, 1)),
}, function(stage: VFXStory.Stage, controls)
	local hand = stage.User:FindFirstChild("RightHand")
	local targetRoot = stage.Target.PrimaryPart
	if not hand or not hand:IsA("BasePart") or not targetRoot then
		return
	end
	local origin = hand.Position
	local function fire(position: Vector3)
		stage.ClientScope.fire(ClientVFXDefinition.Beam, {
			Origin = origin,
			Position = position,
			Thickness = controls.Thickness,
			Color = controls.Color,
			Transparency = controls.Transparency,
			Lifetime = controls.Lifetime,
			IsFading = controls.IsFading,
			Key = if controls.IsPutRight then KEY else nil,
		})
	end
	fire(targetRoot.Position)
	if controls.IsPutRight then
		task.delay(controls.Lifetime / 3, fire, origin:Lerp(targetRoot.Position, 0.5))
	end
end)
