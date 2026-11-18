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
	Size = Vector3.new(3, 3, 3),
	Speed = 20,
	Lifetime = 1,
})
-- the one the fire has unless the character picked one
local COLOR = BrickColor.new("Bright orange").Color
-- of the fire on the fist + of the one it lets go of
local FLAME_SIZE = 2
local BLAZE_SIZE = 12
-- it's a slow, heavy fire that's let go of, not the trail of a shot
local BLAZE_HEAT = 9
-- what's let go of travels upside down: its flames burn down onto whatever it passes over
local BLAZE_TURN = CFrame.Angles(math.pi, 0, 0)
-- Variables
-- References
-- Private Functions
-- Class
-- the fist burns for as long as the tool is out. a ball of fire leaves it the way the avatar faces once the wind-up
-- is over, the first one it runs into is hit + pushed along
local ability = BurstFactory.new("advanced-melee_fire-punch", {
	ReleaseDelay = 0.3,
	SurgeDuration = 0.7,
	Duration = 1,
	RootDuration = 1,
	Reach = 22,
	HitDelay = 0.3,
	HitDuration = 1,
	HitInterval = 1,
	Front = FRONT,
	ReleaseSound = "ForceWhoosh",
})

return table.freeze({
	Layout = ability.Layout,
	Config = ability.Config,
	Front = FRONT,
	-- the fire on the fist as every machine shows it: in the color the character wears the ability in
	getFlame = function(color: Color3?): ClientVFXType.Flame
		return {
			Limb = FRONT.Limb,
			Size = FLAME_SIZE,
			Heat = 0,
			Color = color or COLOR,
		}
	end,
	-- the fire that's let go of as every machine shows it: on the way the front takes from where it has the avatar
	-- itself. nil for an avatar that's missing the hand
	getBlaze = function(character: Model, color: Color3?): ClientVFXType.Bolt?
		local cframe = BurstFactory.getFrontCFrame(character, FRONT)
		if not cframe then
			return nil
		end
		return {
			Origin = cframe.Position,
			Direction = cframe.LookVector,
			Speed = FRONT.Speed,
			Lifetime = FRONT.Lifetime,
			Size = FRONT.Size,
			Color = color or COLOR,
			FireSize = BLAZE_SIZE,
			FireHeat = BLAZE_HEAT,
			Turn = BLAZE_TURN,
		}
	end,
})
