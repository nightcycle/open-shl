--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type FaceCatalogue = AppearanceType.FaceCatalogue
type FaceSlot = AppearanceType.FaceSlot
-- Constants
local FACE_SLOTS: { FaceSlot } = table.freeze({ "Eyes" :: FaceSlot, "Mouth" })
local FACE_CATEGORIES: { [FaceSlot]: string } = table.freeze({
	Eyes = "eyes",
	Mouth = "mouth",
})
local FACE_IMAGES: { [FaceSlot]: { [string]: string } } = table.freeze({
	Eyes = Image["shl-3"].face.eyes,
	Mouth = Image["shl-3"].face.mouth,
})
local FACE_NAMES: { [string]: string } = table.freeze({
	cosmetics_mouth_grimace = "Grimace",
	["cosmetics_mouth_monster-smile"] = "Monster Smile",
	["cosmetics_mouth_normal-smile"] = "Normal Smile",
})
-- a face that was never given a mouth has none
local FACE_DEFAULTS: { [FaceSlot]: string } = table.freeze({
	Eyes = "neutral",
})
-- the eyes are drawn in black + take the color of the character's, brown until one is picked
local FACE_TINTS: { [FaceSlot]: Color3 } = table.freeze({
	Eyes = Color3.fromRGB(116, 88, 57),
})
local FACES: FaceCatalogue = table.freeze({
	Slots = FACE_SLOTS,
	Categories = FACE_CATEGORIES,
	Images = FACE_IMAGES,
	Names = FACE_NAMES,
	Defaults = FACE_DEFAULTS,
	Tints = FACE_TINTS,
})
-- Variables
-- References
-- Private Functions
-- Class
return FACES
