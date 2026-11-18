--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/ServerScriptService/Server/Ability/Factory/Burst")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ForceBlast = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/ForceBlast")
local Shove = require("@game/ServerScriptService/Server/VFX/Library/Shove")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ServerContext = AbilityType.ServerContext
-- Constants
-- studs everybody else sees the wave from
local RIPPLE_RANGE = 150
-- Variables
-- References
-- Private Functions
-- Class
return BurstFactory
	-- whoever the wave lands on is sent off the way the avatar faces, at the pace the wave has: held where it stands,
	-- the avatar still faces the way it let the wave go
	.new(ForceBlast, function(context: ServerContext, target: Model)
		context.VFX.fire(Shove, {
			Target = target,
			Velocity = context.Character:GetPivot().LookVector * ForceBlast.Front.Speed,
		})
	end)
	-- the player's own machine shows them their wave right away, this is for everybody else
	:On(
		ForceBlast.Layout.Bindings.Release,
		function(context: ServerContext)
			local ripple = ForceBlast.getRipple(context.Character)
			if ripple then
				context.VFX.fireClient(
					ClientVFXDefinition.Ripple,
					ripple,
					{ Audience = "Others", Range = RIPPLE_RANGE }
				)
			end
		end
	)
	:Build()
