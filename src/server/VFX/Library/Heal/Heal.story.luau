--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Heal = require("@game/ServerScriptService/Server/VFX/Library/Heal")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the health of whoever gets it is printed with every lot, it starts over from the control once they're whole. it's the
-- user's own unless it's handed to the target
return VFXStory.newEventStory({
	Health = UILabs.Slider(50, 1, 100, 1),
	Amount = UILabs.Slider(1.6, 0, 100, 0.1),
	IsForTarget = UILabs.Boolean(false),
}, function(stage: VFXStory.Stage, controls)
	local user = if controls.IsForTarget then stage.Target else stage.User
	if AttributeDefinition.get(user, AttributeDefinition.Health) >= AttributeDefinition.MAX_HEALTH then
		AttributeDefinition.setDefaults(user, "Character")
		AttributeDefinition.set(user, AttributeDefinition.Health, controls.Health)
	end
	local isHealed = stage.ServerScope.fire(Heal, {
		Amount = controls.Amount,
		Target = if controls.IsForTarget then stage.Target else nil,
	})
	print(`healed: {isHealed}, health: {AttributeDefinition.get(user, AttributeDefinition.Health)}`)
end)
