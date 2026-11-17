--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local Types = {}

export type ExpressionId =
	"Angry"
	| "Sinister"
	| "Hateful"
	| "Skeptical"
	| "Cringing"
	| "Happy"
	| "Nervous"
	| "Guilty"
	| "Awestruck"
	| "Neutral"
	| "Hurt"
	| "Depressed"
	| "Weary"
	| "Sad"
	| "Traumatized"
	| "Surprised"
Types.ExpressionId = Type.literal(
	"Angry",
	"Sinister",
	"Hateful",
	"Skeptical",
	"Cringing",
	"Happy",
	"Nervous",
	"Guilty",
	"Awestruck",
	"Neutral",
	"Hurt",
	"Depressed",
	"Weary",
	"Sad",
	"Traumatized",
	"Surprised"
)

export type ExpressionDefinition = {
	Id: ExpressionId,
	Name: string,
	DefinitionIds: {
		Eyebrows: string,
		Eyes: string,
		Mouth: string,
	},
}
Types.ExpressionDefinition = Type.strictInterface({
	Id = Types.ExpressionId,
	Name = Type.string,
	DefinitionIds = Type.strictInterface({
		Eyebrows = Type.string,
		Eyes = Type.string,
		Mouth = Type.string,
	}),
})

export type PoseDefinition = {
	Name: string,
	AnimationId: string,
	IsLooped: boolean,
	IsRooting: boolean, -- used to determine if the character can walk while it plays
}
Types.PoseDefinition = Type.strictInterface({
	Name = Type.string,
	AnimationId = Type.string,
	IsLooped = Type.boolean,
	IsRooting = Type.boolean,
})

export type EmoteId = "HandsBehindBack" | "HeroicPose" | "Kneel" | "Laugh" | "Point"
Types.EmoteId = Type.literal("HandsBehindBack", "HeroicPose", "Kneel", "Laugh", "Point")

export type EmoteDefinition = {
	Id: EmoteId,
	Name: string,
	AnimationId: string,
	IsLooped: boolean,
	IsRooting: boolean,
}
Types.EmoteDefinition = Type.strictInterface({
	Id = Types.EmoteId,
	Name = Type.string,
	AnimationId = Type.string,
	IsLooped = Type.boolean,
	IsRooting = Type.boolean,
})

return Types
