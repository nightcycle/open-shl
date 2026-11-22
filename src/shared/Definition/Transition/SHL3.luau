--!strict
-- Services
-- Packages
-- Modules
local Animation = require("@game/ReplicatedStorage/Generated/Animation")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local TransitionType = require("@game/ReplicatedStorage/Shared/Type/Transition")
type TransitionCatalogue = TransitionType.TransitionCatalogue
-- Constants
local SPIN_ANIMATION_ID = Animation["shl-3"].transition["spin.rbxm"]
local FALL_FORWARD_ANIMATION_ID = Animation.core.transition["fall-forward.rbxm"]
local SWAP_COOLDOWN = 1
-- its editor has no page for either style, so there's the one of each every character starts out with
local CATALOGUE: TransitionCatalogue = {
	Transformations = {
		-- its own turn on the spot, the costume changes half a second in. how long its switch stays faded for is
		-- the hud's to say
		Spin = {
			Style = PseudoEnum.TransformationStyle.Spin,
			Name = "Spin",
			AnimationId = SPIN_ANIMATION_ID,
			AnimationLength = 1,
			SwapDelay = 0.5,
			LockDuration = 0.5 + SWAP_COOLDOWN,
		},
	},
	Deaths = {
		FallForward = {
			Style = PseudoEnum.DeathStyle.FallForward,
			Name = "Fall Forwards",
			AnimationId = FALL_FORWARD_ANIMATION_ID,
			AnimationLength = 3,
			RespawnDelay = 3,
			FreezeDuration = 3,
		},
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
