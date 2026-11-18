--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Burst")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- the wind around the avatar for as long as the spin goes off, as every machine shows it
local FUNNEL: ClientVFXType.Plume = {
	Limb = "HumanoidRootPart",
	Particle = "Tornado",
}
table.freeze(FUNNEL)
-- Variables
-- References
-- Private Functions
-- Class
-- everybody around is caught the moment the spin begins, the wind only picks up after. the avatar stays held long
-- after the spin itself is over
local ability = BurstFactory.new("advanced-melee_tornado", {
	ReleaseDelay = 0.1,
	SurgeDuration = 1.7,
	Duration = 2,
	RootDuration = 4.3,
	Reach = 12,
	HitDelay = 0,
	HitDuration = 0,
	CastSound = "ForceWhoosh",
})

return table.freeze({
	Layout = ability.Layout,
	Config = ability.Config,
	Funnel = FUNNEL,
})
