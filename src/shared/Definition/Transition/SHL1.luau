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
local FALL_FORWARD_ANIMATION_ID = Animation.core.transition["fall-forward.rbxm"]
-- its editor has no page for either style, so there's the one of each every character starts out with
local CATALOGUE: TransitionCatalogue = {
	Transformations = {
		-- it became the other where it stood with nothing played, + couldn't walk for a second and a half. that
		-- was all that kept the next switch off
		Spin = {
			Style = PseudoEnum.TransformationStyle.Spin,
			Name = "Spin",
			AnimationLength = 0,
			SwapDelay = 0,
			LockDuration = 1.5,
			FreezeDuration = 1.5,
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
