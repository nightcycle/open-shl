--!strict
-- Services
-- Packages
-- Modules
local Animation = require("@game/ReplicatedStorage/Generated/Animation")
-- Types
local RoleplayType = require("@game/ReplicatedStorage/Shared/Type/Roleplay")
type EmoteCatalogue = RoleplayType.EmoteCatalogue
-- Constants
-- animations are owned by the old place
local EMOTES = Animation["shl-3"].emote
-- the one that's roblox's own: it plays in every place + there's no file of it to have
local LAUGH_ANIMATION_ID = "rbxassetid://507770818"
local CATALOGUE: EmoteCatalogue = {
	-- the buttons of its roleplay bar, in the order they're in on it. the two poses root whoever strikes them
	Definitions = {
		{
			Id = "AtEase",
			Name = "At Ease",
			AnimationId = EMOTES["at-ease.rbxm"],
			IsLooped = true,
			IsRooting = false,
		},
		{
			Id = "HeroicPose",
			Name = "Heroic Pose",
			AnimationId = EMOTES["heroic-pose.rbxm"],
			IsLooped = true,
			IsRooting = true,
		},
		{
			Id = "Kneel",
			Name = "Kneel",
			AnimationId = EMOTES["kneel.rbxm"],
			IsLooped = true,
			IsRooting = true,
		},
		{
			Id = "Dab",
			Name = "Dab",
			AnimationId = EMOTES["dab.rbxm"],
			IsLooped = false,
			IsRooting = false,
		},
		{
			Id = "Laugh",
			Name = "Laugh",
			AnimationId = LAUGH_ANIMATION_ID,
			IsLooped = false,
			IsRooting = false,
		},
	},
	-- the arms of the villains its jail holds: the cuffs are the second game's, so is how they're worn
	Handcuffs = {
		Name = "Handcuffs",
		AnimationId = Animation.core.emote["handcuffs.rbxm"],
		IsLooped = true,
		IsRooting = false,
	},
	-- the first button of the bar isn't an emote: a hand goes to the head, what becomes of the mask is the server's
	Mask = {
		Name = "Mask",
		AnimationId = EMOTES["mask.rbxm"],
		IsLooped = false,
		IsRooting = false,
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return CATALOGUE
