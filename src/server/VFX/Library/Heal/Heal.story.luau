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
-- the health of the user is printed with every lot, it starts over from the control once they're whole
return VFXStory.newEventStory({
	Health = UILabs.Slider(50, 1, 100, 1),
	Amount = UILabs.Slider(1.6, 0, 100, 0.1),
}, function(stage: VFXStory.Stage, controls)
	local user = stage.User
	if AttributeDefinition.get(user, AttributeDefinition.Health) >= AttributeDefinition.MAX_HEALTH then
		AttributeDefinition.setDefaults(user, "Character")
		AttributeDefinition.set(user, AttributeDefinition.Health, controls.Health)
	end
	local isHealed = stage.ServerScope.fire(Heal, { Amount = controls.Amount })
	print(`healed: {isHealed}, health: {AttributeDefinition.get(user, AttributeDefinition.Health)}`)
end)
