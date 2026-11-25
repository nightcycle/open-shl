--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Freeze = require("@game/ServerScriptService/Server/VFX/Library/Freeze")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
local TARGETS = { "Target", "User" }
local ICE = Color3.fromRGB(152, 194, 219)
-- Variables
-- References
-- Private Functions
-- Class
-- whether it held + what the attribute says are printed, the attribute again once they're let go. nothing holds in
-- a build without pvp or on the user themselves. a dummy has no client to keep it still: the block is all that shows
return VFXStory.newEventStory({
	Target = UILabs.Choose(TARGETS),
	Duration = UILabs.Slider(5, 0.5, 20, 0.5),
	IsBlocked = UILabs.Boolean(true),
	BlockDuration = UILabs.Slider(7, 0.5, 20, 0.5),
	GrowDuration = UILabs.Slider(1, 0, 5, 0.1),
}, function(stage: VFXStory.Stage, controls)
	local target = if controls.Target == "User" then stage.User else stage.Target
	if target:GetAttribute(AttributeDefinition.Health.Name) == nil then
		AttributeDefinition.setDefaults(target, "Character")
	end
	local isHeld = stage.ServerScope.fire(Freeze, {
		Target = target,
		Duration = controls.Duration,
		BlockDuration = if controls.IsBlocked then controls.BlockDuration else nil,
		Block = if controls.IsBlocked
			then {
				Size = Vector3.new(5, 7, 5),
				Offset = CFrame.new(0, 1, 0),
				Color = ICE,
				Material = Enum.Material.Ice,
				Transparency = 0.3,
				GrowDuration = controls.GrowDuration,
			}
			else nil,
	})
	local function getIfFrozen(): boolean
		return AttributeDefinition.get(target, AttributeDefinition.IsFrozen)
	end
	print(`held: {isHeld}, frozen: {getIfFrozen()}, pvp enabled: {ModeDefinition.getIfPVPEnabled()}`)
	if isHeld then
		task.delay(controls.Duration + 0.1, function()
			if target.Parent then
				print(`frozen after {controls.Duration} s: {getIfFrozen()}`)
			end
		end)
	end
end)
