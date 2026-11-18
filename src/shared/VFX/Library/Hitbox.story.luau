--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Hitbox = require("@game/ReplicatedStorage/Shared/VFX/Library/Hitbox")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the box is drawn around the right hand of the user, it turns green once the target is inside of it
return VFXStory.newStateStory({
	Distance = UILabs.Slider(4, 2, 20, 1),
	Size = UILabs.Slider(5, 1, 16, 0.5),
	Offset = UILabs.Slider(-2, -10, 10, 0.5),
}, function(stage: VFXStory.Stage, controls)
	local hand = stage.User:FindFirstChild("RightHand") :: BasePart
	local size = Vector3.new(1.5, 1.5, controls.Size)
	local offset = CFrame.new(0, 0, controls.Offset)
	local box = Instance.new("BoxHandleAdornment")
	box.Adornee = hand
	box.Size = size
	box.CFrame = offset
	box.Color3 = Color3.new(1, 0, 0)
	box.Transparency = 0.6
	box.AlwaysOnTop = true
	box.Parent = hand
	local handle = stage.ClientScope.start(Hitbox, {
		Part = hand,
		Size = size,
		Offset = offset,
		OnHit = function()
			box.Color3 = Color3.new(0, 1, 0)
		end,
	})
	return function()
		handle.Stop()
		box:Destroy()
	end
end)
