--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Burst")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
local RIPPLE_SIZE = Vector3.new(4, 0.2, 4)
local RIPPLE_END_SIZE = Vector3.new(34, 0.2, 34)
local RIPPLE_LIFETIME = 1
-- Variables
-- References
-- Private Functions
-- Class
-- a wave spreads from the avatar once the wind-up is over, it has got to everybody around by the time it's heard.
-- the avatar stays held for a while after
local ability = BurstFactory.new("advanced-melee_force-explosion", {
	ReleaseDelay = 1.2,
	SurgeDuration = 0.75,
	Duration = 2,
	RootDuration = 2.75,
	Reach = 16.5,
	HitDelay = 1.95,
	HitDuration = 0,
	CastSound = "WindGust",
	SubsideSound = "Boom",
})

return table.freeze({
	Layout = ability.Layout,
	Config = ability.Config,
	-- the wave as every machine shows it: around where it has the avatar itself
	getRipple = function(character: Model): ClientVFXType.Ripple
		return {
			Decal = "Shockwave",
			CFrame = character:GetPivot(),
			Size = RIPPLE_SIZE,
			EndSize = RIPPLE_END_SIZE,
			Lifetime = RIPPLE_LIFETIME,
		}
	end,
})
