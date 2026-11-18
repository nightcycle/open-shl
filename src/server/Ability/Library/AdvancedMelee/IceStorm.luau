--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/ServerScriptService/Server/Ability/Factory/Burst")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local IceStorm = require("@game/ReplicatedStorage/Shared/Ability/Library/AdvancedMelee/IceStorm")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local bindings = IceStorm.Layout.Bindings
-- the player's own machine shows them their icicles + the cold off their hands right away, this is for everybody
-- else. theirs are only there to be seen: who one runs into is for the machine of the player to say
local builder = BurstFactory.new(IceStorm)
	:RunClient(bindings.Surge, ClientVFXDefinition.Spray, function(): ClientVFXType.Spray
		return IceStorm.Spray
	end, { Audience = "Others" })
for _, smoke in IceStorm.Smokes do
	builder = builder:RunClient(bindings.Surge, ClientVFXDefinition.Smoke, function(): ClientVFXType.Smoke
		return smoke
	end, { Audience = "Others" })
end

return builder:Build()
