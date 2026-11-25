--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Burn = require("@game/ServerScriptService/Server/VFX/Library/Burn")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
local TARGETS = { "Target", "User" }
-- Variables
-- References
-- Private Functions
-- Class
-- the health of whoever is set alight is printed as it catches + once the last tick is due, it starts over once
-- they're down. nothing catches in a build without pvp or on the user themselves
return VFXStory.newEventStory({
	Target = UILabs.Choose(TARGETS),
	Amount = UILabs.Slider(4, 0, 50, 1),
	Count = UILabs.Slider(10, 1, 30, 1),
	Interval = UILabs.Slider(0.5, 0.1, 3, 0.1),
	FlameDuration = UILabs.Slider(5, 0, 20, 0.5),
}, function(stage: VFXStory.Stage, controls)
	local target = if controls.Target == "User" then stage.User else stage.Target
	local isNew = target:GetAttribute(AttributeDefinition.Health.Name) == nil
	if isNew or AttributeDefinition.get(target, AttributeDefinition.IsDead) then
		AttributeDefinition.setDefaults(target, "Character")
		local humanoid = target:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end
	end
	local function getHealth(): number
		return AttributeDefinition.get(target, AttributeDefinition.Health)
	end
	local isCaught = stage.ServerScope.fire(Burn, {
		Target = target,
		Amount = controls.Amount,
		Count = controls.Count,
		Interval = controls.Interval,
		FlameDuration = controls.FlameDuration,
	})
	print(`caught: {isCaught}, health: {getHealth()}, pvp enabled: {ModeDefinition.getIfPVPEnabled()}`)
	if isCaught then
		task.delay((controls.Count - 1) * controls.Interval + 0.1, function()
			if target.Parent then
				print(`health after {controls.Count} ticks: {getHealth()}`)
			end
		end)
	end
end)
