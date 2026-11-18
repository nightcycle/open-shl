--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Burst")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
local HANDS = table.freeze({ "LeftHand", "RightHand" })
-- seconds from the click until the first icicles leave + seconds they keep leaving for
local RELEASE_DELAY = 0.5
local VOLLEY_DURATION = 1.25
-- studs a second an icicle leaves at, seconds it flies for at most + what pulls it down on the way
local SPEED = 100
local LIFETIME = 2
local GRAVITY = 196.2
-- the icicles both hands let fly, as every machine shows them
local SPRAY: ClientVFXType.Spray = {
	Limbs = HANDS,
	Interval = 1 / 12,
	-- out of the hand the way the arm points
	Turn = CFrame.Angles(-math.pi / 2, 0, 0),
	Speed = SPEED,
	Lifetime = LIFETIME,
	Gravity = GRAVITY,
	Size = Vector3.new(0.2, 1, 0.2),
	Color = BrickColor.new("Medium stone grey").Color,
	Material = Enum.Material.Plastic,
	Mesh = "Icicle",
}
table.freeze(SPRAY)
-- Variables
-- References
-- Private Functions
-- Class
-- the cold that sinks off each hand for as long as the icicles leave it, as every machine shows it
local smokes: { ClientVFXType.Smoke } = {}
for _, hand in HANDS do
	table.insert(
		smokes,
		table.freeze({
			Limb = hand,
			Size = 4,
			RiseVelocity = -10,
			Opacity = 0.5,
			Color = BrickColor.new("Baby blue").Color,
		})
	)
end
-- icicles leave both hands as the avatar spins, whoever one of them runs into is hit: the same one time + again if
-- they stay in the way, though never more than once in a while
local ability = BurstFactory.new("advanced-melee_ice-storm", {
	ReleaseDelay = RELEASE_DELAY,
	SurgeDuration = VOLLEY_DURATION,
	Duration = 2,
	RootDuration = 2,
	-- as far as an icicle gets before it's pulled into the ground it left from
	Reach = SPEED ^ 2 / GRAVITY,
	HitDelay = RELEASE_DELAY,
	-- the last of them is still in the air long after the cast is over
	HitDuration = VOLLEY_DURATION + LIFETIME,
	HitInterval = 0.7,
	CastSound = "WindGust",
})

return table.freeze({
	Layout = ability.Layout,
	Config = ability.Config,
	Spray = SPRAY,
	Smokes = table.freeze(smokes),
})
