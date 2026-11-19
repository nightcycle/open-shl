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
local FACE_SLOTS: { FaceSlot } = table.freeze({ "Eyebrows" :: FaceSlot, "Eyes", "Mouth" })
local FACE_CATEGORIES: { [FaceSlot]: string } = table.freeze({
	Eyebrows = "eyebrows",
	Eyes = "eyes",
	Mouth = "mouth",
})
local FACE_IMAGES: { [FaceSlot]: { [string]: string } } = table.freeze({
	Eyebrows = Image["shl-2"].face.eyebrows,
	Eyes = Image["shl-2"].face.eyes,
	Mouth = Image["shl-2"].face.mouth,
})
local FACE_NAMES: { [string]: string } = table.freeze({
	cosmetics_eyebrows_worried = "Sad Eyebrows",
})
local FACE_DEFAULTS: { [FaceSlot]: string } = table.freeze({
	Eyebrows = "neutral",
	Eyes = "neutral",
	Mouth = "neutral",
})
-- every face is drawn the way its image is
local FACE_TINTS: { [FaceSlot]: Color3 } = table.freeze({})
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
