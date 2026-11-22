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
local CATALOGUE: EmoteCatalogue = {
	Definitions = {
		{
			Id = "HandsBehindBack",
			Name = "Hands Behind Back",
			AnimationId = Animation["shl-2"].emote["hands-behind-back.rbxm"],
			IsLooped = true,
			IsRooting = true,
		},
		{
			Id = "HeroicPose",
			Name = "Heroic Pose",
			AnimationId = Animation["shl-2"].emote["heroic-pose.rbxm"],
			IsLooped = true,
			IsRooting = true,
		},
		{
			Id = "Kneel",
			Name = "Kneel",
			AnimationId = Animation["shl-2"].emote["kneel.rbxm"],
			IsLooped = true,
			IsRooting = true,
		},
		{
			Id = "Laugh",
			Name = "Laugh",
			AnimationId = Animation["shl-2"].emote["laugh.rbxm"],
			IsLooped = true,
			IsRooting = true,
		},
		{
			Id = "Point",
			Name = "Point",
			AnimationId = Animation["shl-2"].emote["point.rbxm"],
			IsLooped = true,
			IsRooting = true,
		},
	},
	-- not an emote, a cuffed character can still walk around. the arms are held the same way wherever somebody is cuffed
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
