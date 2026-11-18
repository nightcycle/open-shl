--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
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
-- the slab under the user stands in for a stretch of water. it only carries whoever keeps moving, which a dummy never
-- does: whether it's solid is printed as the effect starts + as it stops
return VFXStory.newStateStory({}, function(stage: VFXStory.Stage)
	local slab = Instance.new("Part")
	slab.Name = "Water"
	slab.Size = Vector3.new(12, 0.2, 12)
	slab.Material = Enum.Material.Glass
	slab.Color = BrickColor.new("Bright blue").Color
	slab.Transparency = 0.7
	slab.Anchored = true
	slab.CanCollide = false
	slab.CFrame = stage.User:GetPivot() - Vector3.new(0, 3.1, 0)
	slab.Parent = stage.User.Parent
	local handle = stage.ClientScope.start(ClientVFXDefinition.Skim, { Part = slab })
	print(`solid while on: {slab.CanCollide}`)
	return function()
		handle.Stop()
		print(`solid once off: {slab.CanCollide}`)
		slab:Destroy()
	end
end)
