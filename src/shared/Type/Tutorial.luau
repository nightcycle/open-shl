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

export type SectionId = "Entry" | "Quest" | "Artifact" | "Base" | "Suit"
Types.SectionId = Type.literal("Entry", "Quest", "Artifact", "Base", "Suit")

export type Trigger =
	"HudShown" -- the gameplay hud is on screen for the first time
	| "SwapPressed" -- an identity swap began
	| "CharactersOpened" -- the character select opened
	| "CharacterSelected" -- "Select" was pressed in the character select
	| "EditorOpened" -- "Edit" was pressed in the character select
	| "EditorBack" -- "Back" was pressed in the editor
	| "ArtifactMenuOpened"
	| "BuildPressed" -- the build menu opened
	| "QuestStarted" -- the quest giver handed the player a quest
	| "LobbyEntered" -- walked in the front door of the apartment complex
	| "ApartmentEntered" -- walked in the door of their own apartment
	| "BaseEntered" -- went through the bookshelf into their base
Types.Trigger = Type.literal(
	"HudShown",
	"SwapPressed",
	"CharactersOpened",
	"CharacterSelected",
	"EditorOpened",
	"EditorBack",
	"ArtifactMenuOpened",
	"BuildPressed",
	"QuestStarted",
	"LobbyEntered",
	"ApartmentEntered",
	"BaseEntered"
)

export type Pose = "Fly" | "Idle" | "PointLeft" | "PointRight"
Types.Pose = Type.literal("Fly", "Idle", "PointLeft", "PointRight")

export type BubbleSide = "Left" | "Right"
Types.BubbleSide = Type.literal("Left", "Right")

export type Condition =
	"PvpEnabled"
	| "QuestsEnabled"
	| "QuestSectionPending" -- the quest section hasn't played yet this session
	| "NoActiveQuest"
Types.Condition = Type.literal("PvpEnabled", "QuestsEnabled", "QuestSectionPending", "NoActiveQuest")

export type Home =
	"Hud" -- the gameplay hud
	| "Residence" -- the gameplay hud inside of the player's residence, the build button only exists there
	| "CharacterEditor"
	| "ArtifactMenu"
Types.Home = Type.literal("Hud", "Residence", "CharacterEditor", "ArtifactMenu")

export type Advance =
	{
		Type: "Next", -- the bubble shows its next button
	}
	| {
		Type: "Trigger", -- the next button is hidden until the player does it
		Trigger: Trigger,
	}
Types.Advance = Type.union(
	Type.strictInterface({
		Type = Type.literal("Next"),
	}),
	Type.strictInterface({
		Type = Type.literal("Trigger"),
		Trigger = Types.Trigger,
	})
)

export type StepDefinition =
	{
		Type: "Talk",
		Text: string,
		BubbleSide: BubbleSide,
		Pose: Pose, -- held while talking, he flies there in the fly pose
		CaptainPosition: Vector2, -- in screen scale
		CaptainSize: number, -- in scale of his frame
		MoveDuration: number, -- how long the flight takes when he isn't there already
		Advance: Advance,
		Conditions: { Condition }?,
		Home: Home?, -- only when it isn't the one of its section
	}
	| {
		Type: "Rest", -- he flies back to his corner + stays quiet
		Duration: number,
		Conditions: { Condition }?,
	}
Types.StepDefinition = Type.union(
	Type.strictInterface({
		Type = Type.literal("Talk"),
		Text = Type.string,
		BubbleSide = Types.BubbleSide,
		Pose = Types.Pose,
		CaptainPosition = Type.Vector2,
		CaptainSize = Type.numberPositive,
		MoveDuration = Type.numberMin(0),
		Advance = Types.Advance,
		Conditions = Type.optional(Type.array(Types.Condition)),
		Home = Type.optional(Types.Home),
	}),
	Type.strictInterface({
		Type = Type.literal("Rest"),
		Duration = Type.numberMin(0),
		Conditions = Type.optional(Type.array(Types.Condition)),
	})
)

export type SectionDefinition = {
	Id: SectionId,
	Trigger: Trigger, -- what starts the section
	StartDelay: number, -- seconds between the trigger + the captain flying in
	Conditions: { Condition }?,
	Home: Home, -- where its steps play, he waits in his corner while that's off screen
	Steps: { StepDefinition },
}
Types.SectionDefinition = Type.strictInterface({
	Id = Types.SectionId,
	Trigger = Types.Trigger,
	StartDelay = Type.numberMin(0),
	Conditions = Type.optional(Type.array(Types.Condition)),
	Home = Types.Home,
	Steps = Type.array(Types.StepDefinition),
})

return Types
