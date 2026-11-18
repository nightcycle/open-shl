--!strict
-- Services
-- Packages
-- Modules
local BurstFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Burst")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
local FRONT: BurstFactory.Front = table.freeze({
	Limb = "RightHand",
	Size = Vector3.new(6, 0.2, 3),
	Speed = 20,
	Lifetime = 0.5,
})
-- what the wave has grown to by the time it's gone
local RIPPLE_END_SIZE = Vector3.new(12, 0.2, 4.5)
-- it travels turned over: the picture on its faces is drawn to be seen that way round
local RIPPLE_TURN = CFrame.Angles(math.pi, 0, 0)
-- Variables
-- References
-- Private Functions
-- Class
-- a wave leaves the hand the way the avatar faces once the wind-up is over, the first one it runs into is hit +
-- pushed along
local ability = BurstFactory.new("basic-melee_force-blast", {
	ReleaseDelay = 0.3,
	SurgeDuration = 0.5,
	Duration = 1,
	RootDuration = 1,
	Reach = 12,
	HitDelay = 0.3,
	HitDuration = 0.5,
	HitInterval = 1,
	Front = FRONT,
	ReleaseSound = "ForceWhoosh",
})

return table.freeze({
	Layout = ability.Layout,
	Config = ability.Config,
	Front = FRONT,
	-- the wave as every machine shows it: on the way the front takes from where it has the avatar itself. nil for
	-- an avatar that's missing the hand
	getRipple = function(character: Model): ClientVFXType.Ripple?
		local cframe = BurstFactory.getFrontCFrame(character, FRONT)
		if not cframe then
			return nil
		end
		return {
			Decal = "PsychicWave",
			CFrame = cframe * RIPPLE_TURN,
			Size = FRONT.Size,
			EndSize = RIPPLE_END_SIZE,
			Lifetime = FRONT.Lifetime,
			Velocity = cframe.LookVector * FRONT.Speed,
		}
	end,
})
