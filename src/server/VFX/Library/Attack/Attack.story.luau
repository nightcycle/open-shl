--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Attack = require("@game/ServerScriptService/Server/VFX/Library/Attack")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
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
-- the health of whoever is attacked is printed with every hit, it starts over once they're down. nothing lands in a
-- build without pvp or on the user themselves
return VFXStory.newEventStory({
	Amount = UILabs.Slider(14, 0, 100, 1),
	Target = UILabs.Choose(TARGETS),
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
	local isLanded = stage.ServerScope.fire(Attack, { Target = target, Amount = controls.Amount })
	local health = AttributeDefinition.get(target, AttributeDefinition.Health)
	print(`landed: {isLanded}, health: {health}, pvp enabled: {BUILD_CONFIG.PVP_ENABLED}`)
end)
