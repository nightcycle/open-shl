--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Option = TypeUnionLib.Option
-- Modules
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
type Option<V> = TypeUnionLib.Option<V>
local TutorialType = require("@game/ReplicatedStorage/Shared/Type/Tutorial")
export type SectionId = TutorialType.SectionId
export type Trigger = TutorialType.Trigger
export type Pose = TutorialType.Pose
export type BubbleSide = TutorialType.BubbleSide
export type Condition = TutorialType.Condition
export type Home = TutorialType.Home
export type StepDefinition = TutorialType.StepDefinition
export type SectionDefinition = TutorialType.SectionDefinition
-- Constants
local CAPTAIN_IMAGES = Image["captain-coolguy"]
-- there is one flying image, he uses it whichever way he goes
local POSE_IMAGES: { [Pose]: string } = table.freeze({
	Fly = CAPTAIN_IMAGES["fly-right.png"],
	Idle = CAPTAIN_IMAGES["forward.png"],
	PointLeft = CAPTAIN_IMAGES["point-left.png"],
	PointRight = CAPTAIN_IMAGES["point-right.png"],
})
local BUBBLE_IMAGES: { [BubbleSide]: string } = table.freeze({
	Left = CAPTAIN_IMAGES["dialogue-left.png"],
	Right = CAPTAIN_IMAGES["dialogue-right.png"],
})
-- positions are the middle of the captain in screen scale, sizes scale the square he sits in
-- the side of that square in scale of the screen height
local FRAME_SIZE = 0.25
local DOCK_POSITION = Vector2.new(0.05, 0.875)
local DOCK_SIZE = 0.5
local TALK_SIZE = 1
local MOVE_DURATION = 1
local RESIZE_DURATION = 1
local DISABLED_TRANSPARENCY = 0.65
local CENTER_STAGE = Vector2.new(0.3, 0.5)
local BASE_STAGE = Vector2.new(0.35, 0.4)
-- between the two mode buttons, so he can point at either
local MODE_STAGE = Vector2.new(0.5, 0.45)
-- each of these leaves him pointing at the thing he talks about
local SWAP_BUTTON_SPOT = Vector2.new(0.82, 0.45)
local CHARACTERS_BUTTON_SPOT = Vector2.new(0.82, 0.55)
local BUILD_BUTTON_SPOT = Vector2.new(0.15, 0.75)
local EDITOR_EXPLORER_SPOT = Vector2.new(0.4, 0.4)
local PVP_CONDITIONS: { Condition } = { "PvpEnabled" }
local QUEST_CONDITIONS: { Condition } = { "QuestsEnabled" }
local QUEST_OFFER_CONDITIONS: { Condition } = { "QuestsEnabled", "QuestSectionPending", "NoActiveQuest" }
local SECTION_IDS: { SectionId } = table.freeze({ "Mode" :: SectionId, "Entry", "Quest", "Artifact", "Base", "Suit" })
-- Variables
-- References
-- Private Functions
local function newTalkStep(
	position: Vector2,
	pose: Pose,
	bubbleSide: BubbleSide,
	text: string,
	trigger: Trigger?,
	conditions: { Condition }?,
	moveDuration: number?,
	home: Home?
): StepDefinition
	return {
		Type = "Talk" :: "Talk",
		Text = text,
		BubbleSide = bubbleSide,
		Pose = pose,
		CaptainPosition = position,
		CaptainSize = TALK_SIZE,
		MoveDuration = moveDuration or MOVE_DURATION,
		Advance = if trigger
			then {
				Type = "Trigger" :: "Trigger",
				Trigger = trigger,
			}
			else {
				Type = "Next" :: "Next",
			},
		Conditions = conditions,
		Home = home,
	}
end

local function newRestStep(duration: number): StepDefinition
	return {
		Type = "Rest" :: "Rest",
		Duration = duration,
	}
end

local function getIfConditionMet(condition: Condition, isQuestSectionDone: boolean, hasActiveQuest: boolean): boolean
	if condition == "PvpEnabled" then
		return BUILD_CONFIG.PVP_ENABLED
	elseif condition == "QuestsEnabled" then
		return BUILD_CONFIG.QUESTS_ENABLED
	elseif condition == "QuestSectionPending" then
		return not isQuestSectionDone
	else
		return not hasActiveQuest
	end
end

-- Class
local Module = {}

Module.POSE_IMAGES = POSE_IMAGES
Module.BUBBLE_IMAGES = BUBBLE_IMAGES
Module.FRAME_SIZE = FRAME_SIZE
Module.DOCK_POSITION = DOCK_POSITION
Module.DOCK_SIZE = DOCK_SIZE
Module.DOCK_DURATION = MOVE_DURATION
Module.RESIZE_DURATION = RESIZE_DURATION
Module.EASING_STYLE = Enum.EasingStyle.Quad
Module.EASING_DIRECTION = Enum.EasingDirection.Out
Module.DISABLED_TRANSPARENCY = DISABLED_TRANSPARENCY

local SECTIONS: { [SectionId]: SectionDefinition } = {
	Mode = {
		Id = "Mode",
		Trigger = "ModeSelectShown",
		StartDelay = 3,
		Home = "ModeSelect",
		Steps = {
			newTalkStep(MODE_STAGE, "Idle", "Right", "Hello! I am Captain Coolguy"),
			newTalkStep(MODE_STAGE, "Idle", "Right", "You know what makes me so cool?"),
			newTalkStep(MODE_STAGE, "Idle", "Right", "Because I help people"),
			newTalkStep(MODE_STAGE, "Idle", "Right", "Also I got laser toes"),
			newTalkStep(MODE_STAGE, "Idle", "Right", "But that's not important right now."),
			newTalkStep(
				MODE_STAGE,
				"Idle",
				"Right",
				"If you think you know what to do, click me and I'll leave you alone."
			),
			newTalkStep(MODE_STAGE, "Idle", "Right", "Let me tell you about SHL II"),
			newTalkStep(MODE_STAGE, "PointLeft", "Right", "On the left is Combat mode: the full experience."),
			newTalkStep(
				MODE_STAGE,
				"PointLeft",
				"Right",
				"In combat mode you can fight other players and complete quests"
			),
			newTalkStep(MODE_STAGE, "PointLeft", "Right", "It is also best place to play to earn currency!"),
			newTalkStep(MODE_STAGE, "PointRight", "Left", "Roleplay mode is like combat mode without all the danger"),
			newTalkStep(MODE_STAGE, "PointRight", "Left", "However you cannot participate in dangerous quests here."),
			newTalkStep(MODE_STAGE, "PointRight", "Left", "But you can craft your own legend surrounded by friends!"),
			newTalkStep(MODE_STAGE, "PointRight", "Left", "Enjoy your time in this game!"),
		},
	},
	Entry = {
		Id = "Entry",
		Trigger = "HudShown",
		StartDelay = 0,
		Home = "Hud",
		Steps = {
			newTalkStep(CENTER_STAGE, "Idle", "Right", "You are now a superhero!"),
			newTalkStep(
				CENTER_STAGE,
				"Idle",
				"Right",
				"Defeat other players in battle to earn credits!",
				nil,
				PVP_CONDITIONS
			),
			newTalkStep(
				SWAP_BUTTON_SPOT,
				"PointRight",
				"Left",
				"Press this button to change into your secret identity.",
				"SwapPressed"
			),
			newTalkStep(
				CHARACTERS_BUTTON_SPOT,
				"PointRight",
				"Left",
				"Press this button to change your suits",
				"CharactersOpened",
				nil,
				0.6
			),
			newTalkStep(CHARACTERS_BUTTON_SPOT, "Idle", "Left", "Feel free to choose a new one!", "CharacterSelected"),
			newTalkStep(CHARACTERS_BUTTON_SPOT, "Idle", "Left", "Spend a minute getting used to your powers!"),
			newRestStep(60),
			newTalkStep(CENTER_STAGE, "Idle", "Right", "Let's go on a quest!", nil, QUEST_OFFER_CONDITIONS),
			newTalkStep(
				CENTER_STAGE,
				"Idle",
				"Right",
				"Look around for a man in a trenchcoat!",
				nil,
				QUEST_OFFER_CONDITIONS
			),
			newTalkStep(CENTER_STAGE, "Idle", "Right", "Be sure to explore the rest of the gui's at your leisure!"),
			newTalkStep(CENTER_STAGE, "Idle", "Right", "There are some pretty cool things there!"),
		},
	},
	Quest = {
		Id = "Quest",
		Trigger = "QuestStarted",
		StartDelay = 3,
		Conditions = QUEST_CONDITIONS,
		Home = "Hud",
		Steps = {
			newTalkStep(CENTER_STAGE, "Idle", "Right", "Congratulations on choosing your first quest!"),
			newTalkStep(CENTER_STAGE, "Idle", "Right", "If you succeed you may recieve gems or credits!"),
			newTalkStep(CENTER_STAGE, "Idle", "Right", "Different quests give you different sized rewards!"),
			newTalkStep(CENTER_STAGE, "Idle", "Right", "So be sure to try them all!"),
			newTalkStep(CENTER_STAGE, "Idle", "Right", "Good luck on the quest!"),
		},
	},
	Artifact = {
		Id = "Artifact",
		Trigger = "ArtifactMenuOpened",
		StartDelay = 0,
		Home = "ArtifactMenu",
		Steps = {
			newTalkStep(CENTER_STAGE, "Idle", "Right", "Welcome to the Artifact Manager!"),
			newTalkStep(CENTER_STAGE, "PointLeft", "Right", "Here is a list of all the artifacts available"),
			newTalkStep(CENTER_STAGE, "PointLeft", "Right", "All of them can be worn on your character"),
			newTalkStep(CENTER_STAGE, "Idle", "Right", "People who wear artifacts are almost as cool as me! *Almost*"),
		},
	},
	Base = {
		Id = "Base",
		Trigger = "LobbyEntered",
		StartDelay = 0,
		Home = "Residence",
		Steps = {
			-- the lobby isn't the residence yet, he leads the player to it over the plain hud
			newTalkStep(BASE_STAGE, "Idle", "Right", "Welcome to the apartment complex!", nil, nil, nil, "Hud"),
			newTalkStep(
				BASE_STAGE,
				"Idle",
				"Right",
				"Look for your name next to a door, then enter your room!",
				"ApartmentEntered",
				nil,
				nil,
				"Hud"
			),
			newTalkStep(BASE_STAGE, "Idle", "Right", "Welcome to your apartment!"),
			newTalkStep(
				BASE_STAGE,
				"Idle",
				"Right",
				"Touch the bookshelf to open it and enter your base!",
				"BaseEntered"
			),
			newTalkStep(BASE_STAGE, "Idle", "Right", "Welcome to your secret base!"),
			newTalkStep(BASE_STAGE, "Idle", "Right", "It's pretty cool - mine is cooler though!"),
			newTalkStep(
				BUILD_BUTTON_SPOT,
				"PointLeft",
				"Right",
				"Press this button to open the base customization menu.",
				"BuildPressed"
			),
			newTalkStep(BASE_STAGE, "Idle", "Right", "Buy a punching bag, and I'll lead you through how to place it"),
			newTalkStep(
				BASE_STAGE,
				"Idle",
				"Right",
				"After purchase, click/tap the center of one of the blue pads to place the item"
			),
			newTalkStep(BASE_STAGE, "Idle", "Right", "Click/Tap the object to edit its position and rotation"),
			newTalkStep(BASE_STAGE, "Idle", "Right", "You are also able to change the color scheme"),
			newTalkStep(BASE_STAGE, "Idle", "Right", "But you will need more credits for that"),
			newTalkStep(BASE_STAGE, "Idle", "Right", "Currently you can have up to 70 items placed at the same time"),
			newTalkStep(BASE_STAGE, "Idle", "Right", "The base automatically saves whenever you place an item"),
			newTalkStep(BASE_STAGE, "Idle", "Right", "Items with gear icons next to them are functional."),
			newTalkStep(BASE_STAGE, "Idle", "Right", "Enjoy customizing your base! New items added all the time!"),
		},
	},
	Suit = {
		Id = "Suit",
		Trigger = "EditorOpened",
		StartDelay = 0,
		Home = "CharacterEditor",
		Steps = {
			newTalkStep(CENTER_STAGE, "Idle", "Right", "Welcome to the suit editor!"),
			newTalkStep(
				CENTER_STAGE,
				"Idle",
				"Right",
				"Here is where you can change nearly every aspect of your character"
			),
			newTalkStep(
				EDITOR_EXPLORER_SPOT,
				"PointLeft",
				"Right",
				"I would advise selecting the 'Basic Information' category"
			),
			newTalkStep(
				EDITOR_EXPLORER_SPOT,
				"PointLeft",
				"Right",
				"Here you can choose your powers, your ethnicity, also your backstory, name, and more!"
			),
			newTalkStep(EDITOR_EXPLORER_SPOT, "PointLeft", "Right", "Go back to the categories", "EditorBack"),
			newTalkStep(EDITOR_EXPLORER_SPOT, "PointLeft", "Right", "Select the emblems category"),
			newTalkStep(
				EDITOR_EXPLORER_SPOT,
				"PointLeft",
				"Right",
				"Select an emblem to test what it looks like on your character"
			),
			newTalkStep(
				EDITOR_EXPLORER_SPOT,
				"PointLeft",
				"Right",
				"Press the add button to insert the new emblem to the character"
			),
			newTalkStep(EDITOR_EXPLORER_SPOT, "PointLeft", "Right", "This same button can remove placed items as well"),
			newTalkStep(
				EDITOR_EXPLORER_SPOT,
				"PointLeft",
				"Right",
				"Below that button you can change the colors and materials of the item"
			),
			newTalkStep(
				EDITOR_EXPLORER_SPOT,
				"PointLeft",
				"Right",
				"Emblems and Masks can be further customized below those"
			),
			newTalkStep(EDITOR_EXPLORER_SPOT, "PointLeft", "Right", "Have fun exploring the other categories!"),
		},
	},
}
TableUtil.deepFreeze(SECTIONS)

for sectionId, SECTION in SECTIONS do
	assert(TutorialType.SectionDefinition(SECTION))
	assert(SECTION.Id == sectionId, `"{sectionId}" section is filed under the wrong id`)
end

Module.get = function(sectionId: SectionId): SectionDefinition
	return SECTIONS[sectionId]
end

Module.list = function(): { SectionDefinition }
	local out: { SectionDefinition } = {}
	for _, sectionId: SectionId in SECTION_IDS do
		table.insert(out, SECTIONS[sectionId])
	end
	table.freeze(out)
	return out
end

Module.getFromTrigger = function(trigger: Trigger): Option<SectionDefinition>
	for _, sectionId: SectionId in SECTION_IDS do
		if SECTIONS[sectionId].Trigger == trigger then
			return Option.some(SECTIONS[sectionId])
		end
	end
	return Option.none()
end

Module.getHome = function(sectionId: SectionId, stepIndex: number): Home
	local section = SECTIONS[sectionId]
	local step: StepDefinition? = section.Steps[stepIndex]
	if step and step.Type == "Talk" and step.Home then
		return step.Home
	end
	return section.Home
end

Module.getIfShown = function(conditions: { Condition }?, isQuestSectionDone: boolean, hasActiveQuest: boolean): boolean
	if conditions == nil then
		return true
	end
	for _, condition: Condition in conditions do
		if not getIfConditionMet(condition, isQuestSectionDone, hasActiveQuest) then
			return false
		end
	end
	return true
end

return Module
