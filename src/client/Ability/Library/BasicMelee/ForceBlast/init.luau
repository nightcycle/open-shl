--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Burst")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ForceBlast = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/ForceBlast")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ClientContext = AbilityType.ClientContext
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return BurstFactory.new(ForceBlast, {
	CastAnimation = "ForcePush",
})
	:On(ForceBlast.Layout.Bindings.Release, function(context: ClientContext)
		local ripple = ForceBlast.getRipple(context.Character)
		if ripple then
			context.VFX.fire(ClientVFXDefinition.Ripple, ripple)
		end
	end)
	:Build()
