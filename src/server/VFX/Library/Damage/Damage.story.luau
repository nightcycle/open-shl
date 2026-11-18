--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Damage = require("@game/ServerScriptService/Server/VFX/Library/Damage")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the health of the target is printed with every hit, it starts over once the target is down
return VFXStory.newEventStory({
	Amount = UILabs.Slider(14, 0, 100, 1),
}, function(stage: VFXStory.Stage, controls)
	local target = stage.Target
	if AttributeDefinition.get(target, AttributeDefinition.IsDead) then
		AttributeDefinition.setDefaults(target, "Character")
		local humanoid = target:FindFirstChildWhichIsA("Humanoid")
		if humanoid then
			humanoid.Health = humanoid.MaxHealth
		end
	end
	local isHit = stage.ServerScope.fire(Damage, { Target = target, Amount = controls.Amount })
	print(`hit: {isHit}, health: {AttributeDefinition.get(target, AttributeDefinition.Health)}`)
end)
