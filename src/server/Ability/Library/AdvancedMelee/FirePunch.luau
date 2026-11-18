--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/ServerScriptService/Server/Ability/Factory/Burst")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local FirePunch = require("@game/ReplicatedStorage/Shared/Ability/Library/AdvancedMelee/FirePunch")
local Shove = require("@game/ServerScriptService/Server/VFX/Library/Shove")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- Constants
-- studs everybody else sees the fire that's let go of from
local BLAZE_RANGE = 150
-- Variables
-- References
-- Private Functions
-- Class
local bindings = FirePunch.Layout.Bindings
return BurstFactory
	-- whoever the fire lands on is sent off the way the avatar faces, at the pace the fire has: held where it stands,
	-- the avatar still faces the way it let the fire go
	.new(FirePunch, function(context: ServerContext, target: Model)
		context.VFX.fire(Shove, {
			Target = target,
			Velocity = context.Character:GetPivot().LookVector * FirePunch.Front.Speed,
		})
	end)
	-- the player's own machine shows them their fire right away, this is for everybody else
	:RunClient(
		bindings.Hold,
		ClientVFXDefinition.Flame,
		function(context: ServerContext): ClientVFXType.Flame
			return FirePunch.getFlame(context.Color)
		end,
		{ Audience = "Others" }
	)
	:On(bindings.Release, function(context: ServerContext)
		local blaze = FirePunch.getBlaze(context.Character, context.Color)
		if blaze then
			context.VFX.fireClient(ClientVFXDefinition.Bolt, blaze, { Audience = "Others", Range = BLAZE_RANGE })
		end
	end)
	:Build()
