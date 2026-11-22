--!strict
-- Services
-- Packages
-- Modules
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local CombatType = require("@game/ReplicatedStorage/Shared/Type/Combat")
type IdentityKey = CharacterType.IdentityKey
type TeamId = CombatType.TeamId
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- every avatar of a villain comes in as the civilian, in an orange t-shirt + jeans. where they are is looked at once
-- a second, the pace its old client reported its own distance at. a road counts from six studs under the root: a
-- touch of any limb did there, which only the client of the limb could say. the powers are back a second after
-- they're let go. a gate is out of the way for four seconds, a tenth of one fading either way. the card off the pad
-- of the prison opens one, in the hand + not put away
return table.freeze({
	TeamId = "Villains" :: TeamId,
	IdentityKey = "Secret" :: IdentityKey,
	ItemIds = table.freeze({ "clothing_shirts_t-shirt", "clothing_pants_jeans" }),
	Color = Color3.fromRGB(218, 133, 65),
	CheckInterval = 1,
	RoadReach = 6,
	ReleaseDelay = 1,
	Gate = table.freeze({
		OpenDuration = 4,
		FadeDuration = 0.1,
		FadeTransparency = 0.925,
		OpenTransparency = 1,
	}),
	KeyPropId = "keycard",
})
