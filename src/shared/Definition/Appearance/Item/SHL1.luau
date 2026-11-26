--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type FaceCatalogue = AppearanceType.FaceCatalogue
type FaceSlot = AppearanceType.FaceSlot
type ItemOrder = AppearanceType.ItemOrder
type Lock = EconomyType.Lock
-- Constants
-- a face is one picture
local FACE_SLOTS: { FaceSlot } = table.freeze({ "Face" :: FaceSlot })
local FACE_CATEGORIES: { [FaceSlot]: string } = table.freeze({
	Face = "face",
})
local FACE_IMAGES: { [FaceSlot]: { [string]: string } } = table.freeze({
	Face = Image["shl-1"].face,
})
-- the old creator showed no name at all, a face went by its place on the list
local FACE_NAMES: { [string]: string } = table.freeze({
	["cosmetics_face_head-0"] = "Face",
	["cosmetics_face_head-1"] = "Face 1",
	["cosmetics_face_head-2"] = "Face 2",
	["cosmetics_face_head-3"] = "Face 3",
	["cosmetics_face_head-4"] = "Face 4",
	["cosmetics_face_head-5"] = "Face 5",
	["cosmetics_face_head-6"] = "Face 6",
	["cosmetics_face_head-7"] = "Face 7",
	["cosmetics_face_head-8"] = "Face 8",
	["cosmetics_face_head-9"] = "Face 9",
	["cosmetics_face_head-10"] = "Face 10",
	["cosmetics_face_head-11"] = "Face 11",
	["cosmetics_face_head-12"] = "Face 12",
})
-- what a character that never picked a face has. it's on no list, nobody picks it
local FACE_DEFAULTS: { [FaceSlot]: string } = table.freeze({
	Face = "head-0",
})
-- every face is drawn the way its image is
local FACE_TINTS: { [FaceSlot]: Color3 } = table.freeze({})
-- what's past the starters of a list is behind the lock of that list. a pass opens it for good, + its lock says what
-- a visit with a piece behind it costs whoever goes without. what the group opens is never rented. the five limbs
-- of a suit share one lock: a suit is rented + kept as one thing, however many of its limbs are on
local SUIT_LOCK: Lock = { Id = "suit", Type = "Entitlement", Key = "PremiumSuits", RentPrice = 25 }
local FACE_LOCK: Lock = { Id = "face", Type = "Entitlement", Key = "PremiumFaces", RentPrice = 20 }
local HAIR_LOCK: Lock = { Id = "hair", Type = "Entitlement", Key = "PremiumHair", RentPrice = 20 }
local HAT_LOCK: Lock = { Id = "hat", Type = "Entitlement", Key = "PremiumMasks", RentPrice = 25 }
local EMBLEM_LOCK: Lock = { Id = "emblem", Type = "GroupPerk" }
for _, lock in { SUIT_LOCK, FACE_LOCK, HAIR_LOCK, HAT_LOCK, EMBLEM_LOCK } do
	table.freeze(lock)
end
-- the nine suits, in the order the old creator walked them. the first three were anybody's on every limb
local SUIT_ORDER: ItemOrder = table.freeze({
	Keys = table.freeze({
		"cyborg",
		"human",
		"mutant",
		"mutant-3",
		"mutant-4",
		"mutant-5",
		"mercenary",
		"mutant-2",
		"tux",
	}),
	StarterCount = 3,
	Lock = SUIT_LOCK,
})
local FACE_ORDER: ItemOrder = table.freeze({
	Keys = table.freeze({
		"head-1",
		"head-2",
		"head-3",
		"head-4",
		"head-5",
		"head-6",
		"head-7",
		"head-8",
		"head-9",
		"head-10",
		"head-11",
		"head-12",
	}),
	StarterCount = 6,
	Lock = FACE_LOCK,
})
-- one hair was on the old list twice, here it's there once
local HAIR_ORDER: ItemOrder = table.freeze({
	Keys = table.freeze({
		"roblohunk-hair",
		"swoosh-hair",
		"mohawk-hair",
		"wavy-hair",
		"lovely-locks-hair",
		"stylish-hair",
		"scene-hair",
		"politician-hair",
		"manga-hero-hair",
		"miss-hair",
		"club-kid-hair",
		"shaggy-hair",
		"princeton-hair",
		"fabulous-hair",
		"bob-hair",
		"animazinghair",
		"hair-12",
		"beautiful-people-hair",
		"beautiful-hair",
		"dream-hair",
		"ultraflash-hair",
	}),
	StarterCount = 11,
	Lock = HAIR_LOCK,
})
local HAT_ORDER: ItemOrder = table.freeze({
	Keys = table.freeze({
		"hat-1",
		"hat-2",
		"hat-3",
		"hat-4",
		"hat-5",
		"hat-6",
		"hat-13",
		"hat-14",
		"hat-15",
		"hat-16",
		"hat-8",
		"hat-9",
		"hat-10",
		"hat-11",
		"hat-12",
	}),
	StarterCount = 6,
	Lock = HAT_LOCK,
})
local EMBLEM_ORDER: ItemOrder = table.freeze({
	Keys = table.freeze({ "emblem-1", "emblem-2", "emblem-3", "emblem-4", "emblem-5", "emblem-6" }),
	StarterCount = 3,
	Lock = EMBLEM_LOCK,
})
local CAPE_ORDER: ItemOrder = table.freeze({
	Keys = table.freeze({ "cape-1", "cape-2", "cape-3" }),
})
local EXTRA_ORDER: ItemOrder = table.freeze({
	Keys = table.freeze({ "jetpack", "katana-holder", "left-gun-arm", "right-gun-arm" }),
})
-- every list of the old creator in its order, the ones anybody could pick ahead of the ones behind a pass or the
-- group. going without was an entry of some lists, here it's wearing nothing + on none of them
local ORDERS: { [string]: ItemOrder } = table.freeze({
	["cosmetics/face"] = FACE_ORDER,
	["cosmetics/hair"] = HAIR_ORDER,
	["costume/suit-torso"] = SUIT_ORDER,
	["costume/suit-left-arm"] = SUIT_ORDER,
	["costume/suit-right-arm"] = SUIT_ORDER,
	["costume/suit-left-leg"] = SUIT_ORDER,
	["costume/suit-right-leg"] = SUIT_ORDER,
	["costume/hats"] = HAT_ORDER,
	["costume/emblems"] = EMBLEM_ORDER,
	["costume/capes"] = CAPE_ORDER,
	["costume/extras"] = EXTRA_ORDER,
})
local FACES: FaceCatalogue = table.freeze({
	Slots = FACE_SLOTS,
	Categories = FACE_CATEGORIES,
	Images = FACE_IMAGES,
	Names = FACE_NAMES,
	Defaults = FACE_DEFAULTS,
	Tints = FACE_TINTS,
	Orders = ORDERS,
})
-- Variables
-- References
-- Private Functions
-- Class
return FACES
