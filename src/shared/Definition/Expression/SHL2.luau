--!strict
-- Services
-- Packages
-- Modules
-- Types
local RoleplayType = require("@game/ReplicatedStorage/Shared/Type/Roleplay")
type ExpressionFace = RoleplayType.ExpressionFace
-- Constants
-- each slot holds the key of its face image
local FACES: { ExpressionFace } = {
	{ Id = "Angry", Name = "Angry", Eyebrows = "angry", Eyes = "angry", Mouth = "angry" },
	{ Id = "Sinister", Name = "Sinister", Eyebrows = "angry", Eyes = "angry", Mouth = "happy" },
	{ Id = "Hateful", Name = "Hateful", Eyebrows = "angry", Eyes = "angry", Mouth = "neutral" },
	{ Id = "Skeptical", Name = "Skeptical", Eyebrows = "angry", Eyes = "angry", Mouth = "sad" },
	{ Id = "Cringing", Name = "Cringing", Eyebrows = "happy", Eyes = "neutral", Mouth = "angry" },
	{ Id = "Happy", Name = "Happy", Eyebrows = "happy", Eyes = "neutral", Mouth = "happy" },
	{ Id = "Nervous", Name = "Nervous", Eyebrows = "happy", Eyes = "neutral", Mouth = "neutral" },
	{ Id = "Guilty", Name = "Guilty", Eyebrows = "happy", Eyes = "neutral", Mouth = "sad" },
	{ Id = "Awestruck", Name = "Awestruck", Eyebrows = "happy", Eyes = "neutral", Mouth = "surprised" },
	{ Id = "Neutral", Name = "Neutral", Eyebrows = "neutral", Eyes = "neutral", Mouth = "neutral" },
	{ Id = "Hurt", Name = "Hurt", Eyebrows = "neutral", Eyes = "neutral", Mouth = "sad" },
	{ Id = "Depressed", Name = "Depressed", Eyebrows = "worried", Eyes = "sad", Mouth = "angry" },
	{ Id = "Weary", Name = "Weary", Eyebrows = "worried", Eyes = "sad", Mouth = "happy" },
	{ Id = "Sad", Name = "Sad", Eyebrows = "worried", Eyes = "sad", Mouth = "sad" },
	{ Id = "Traumatized", Name = "Traumatized", Eyebrows = "surprised", Eyes = "surprised", Mouth = "neutral" },
	{ Id = "Surprised", Name = "Surprised", Eyebrows = "surprised", Eyes = "surprised", Mouth = "surprised" },
}
-- Variables
-- References
-- Private Functions
-- Class
return FACES
