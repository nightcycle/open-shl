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
	Eyebrows = Image.face.eyebrows,
	Eyes = Image.face.eyes,
	Mouth = Image.face.mouth,
})
local FACE_NAMES: { [string]: string } = table.freeze({
	cosmetics_eyebrows_worried = "Sad Eyebrows",
})
local FACES: FaceCatalogue = table.freeze({
	Slots = FACE_SLOTS,
	Categories = FACE_CATEGORIES,
	Images = FACE_IMAGES,
	Names = FACE_NAMES,
})
-- Variables
-- References
-- Private Functions
-- Class
return FACES
