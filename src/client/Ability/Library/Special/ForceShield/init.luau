--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ForceShield = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/ForceShield")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local layout = ForceShield.Layout
-- the shield is the server's to raise, all the player's own machine adds is how they stand behind it
return AbilityBuilder.newClient(layout)
	:Run(layout.Bindings.Hold, ClientVFXDefinition.Animation, function(): ClientVFXType.Animation
		return { Animation = "GunHolding" }
	end)
	:Build()
