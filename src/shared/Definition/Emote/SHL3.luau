--!strict
-- Services
-- Packages
-- Modules
local Animation = require("@game/ReplicatedStorage/Generated/Animation")
-- Types
local RoleplayType = require("@game/ReplicatedStorage/Shared/Type/Roleplay")
type EmoteCatalogue = RoleplayType.EmoteCatalogue
-- Constants
local CATALOGUE: EmoteCatalogue = {
	-- the dances of its roleplay bar aren't built yet, nobody has anything to act out
	Definitions = {},
	-- the arms of the villains its jail holds: the cuffs are the second game's, so is how they're worn
	Handcuffs = {
		Name = "Handcuffs",
		AnimationId = Animation.core.emote["handcuffs.rbxm"],
		IsLooped = true,
		IsRooting = false,
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
