--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ConsumableFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Factory/Consumable")
local IceCream = require("@game/ReplicatedStorage/Shared/Prop/Library/IceCream")
local PropMoment = require("@game/ReplicatedStorage/Shared/Prop/Moment")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- Variables
-- References
-- Private Functions
local function getSound(): ClientVFXType.Sound
	return IceCream.Consumable.UseSound
end
-- Class
-- the lick is heard as it's over, not as it starts. whether it came too soon is the server's to say: the line + the
-- health it costs come from there
return ConsumableFactory.new(IceCream.Consumable)
	:Clear(PropMoment.Use)
	:Fire(PropMoment.Finish, ClientVFXDefinition.Sound, getSound)
	:Build()
