--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local EnergyWarned = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Library/EnergyWarning/Warned")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- what the user has left is printed with every spend, along with whether their hud was warned. they're filled up
-- again after one that was refused. nothing is taken in a build without energy
return VFXStory.newEventStory({
	Amount = UILabs.Slider(12, 0, 200, 1),
}, function(stage: VFXStory.Stage, controls)
	local user = stage.User
	if user:GetAttribute(AttributeDefinition.Energy.Name) == nil then
		AttributeDefinition.setDefaults(user, "Character")
	end
	local isWarned = false
	local connection = EnergyWarned:Connect(function()
		isWarned = true
	end)
	local isSpent = stage.ServerScope.fire(SpendEnergy, { Amount = controls.Amount })
	connection:Disconnect()
	local energy = AttributeDefinition.get(user, AttributeDefinition.Energy)
	print(`spent: {isSpent}, warned: {isWarned}, energy: {energy}, energy enabled: {BUILD_CONFIG.ENERGY_ENABLED}`)
	if not isSpent then
		AttributeDefinition.setDefaults(user, "Character")
	end
end)
