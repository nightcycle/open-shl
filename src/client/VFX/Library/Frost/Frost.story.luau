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
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
local COLORS = table.freeze({
	BrickColor.new("Bright blue").Color,
	BrickColor.new("Teal").Color,
	BrickColor.new("Deep blue").Color,
})
-- Variables
-- References
-- Private Functions
-- Class
-- a cluster grows around the target: every block is a size bigger than the one before + takes as much longer to
-- get there, each with a turn + a color of its own
return VFXStory.newEventStory({
	BlockCount = UILabs.Slider(7, 1, 12, 1),
	GrowStep = UILabs.Slider(0.33, 0, 2, 0.01),
	Lifetime = UILabs.Slider(3, 0.1, 15, 0.1),
	ShrinkDuration = UILabs.Slider(0, 0, 5, 0.1),
	Seed = UILabs.Slider(1, 1, 100, 1),
}, function(stage: VFXStory.Stage, controls)
	local random = Random.new(controls.Seed)
	local blocks: { ClientVFXType.FrostBlock } = {}
	for index = 1, controls.BlockCount do
		local turn = CFrame.Angles(
			random:NextNumber(0, math.pi * 2),
			random:NextNumber(0, math.pi * 2),
			random:NextNumber(0, math.pi * 2)
		)
		table.insert(blocks, {
			Size = Vector3.one * random:NextInteger(math.max(index - 3, 1), index + 1),
			Offset = turn,
			GrowDuration = index * controls.GrowStep,
			Color = COLORS[random:NextInteger(1, #COLORS)],
		})
	end
	stage.ClientScope.fire(ClientVFXDefinition.Frost, {
		CFrame = stage.Target:GetPivot(),
		Blocks = blocks,
		Lifetime = controls.Lifetime,
		ShrinkDuration = controls.ShrinkDuration,
	})
end)
