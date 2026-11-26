--!strict
-- Services
-- Packages
-- Modules
local PropDefinition = require("@game/ReplicatedStorage/Shared/Definition/Prop")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type AnimationKey = VFXAssetDefinition.AnimationKey
type SoundKey = VFXAssetDefinition.SoundKey
-- Constants
local ID = "moneybag"
-- the arm out in front, what a hand that holds anything used to do by itself. the old tool swung the shoulder by
-- hand for a throw, a write nothing shows of on a body that's animated
local HOLD_ANIMATION: AnimationKey = "GunHolding"
local LOOK: ClientVFXType.Prop = table.freeze({
	Limb = "RightHand",
	Size = Vector3.new(1, 0.8, 1),
	-- of the hand from it, the way the old tool gripped it
	Offset = CFrame.new(-0.169, 0.485, -0.011, 0, -1, 0, 0, 0, -1, 1, 0, 0),
	-- the mesh is drawn by its texture, the part under it never shows
	Color = Color3.new(1, 1, 1),
	Mesh = "Moneybag" :: "Moneybag",
	MeshScale = Vector3.new(0.5, 0.6, 0.5),
})
-- a handful of bills: each starts a little way out from the bag + above it, falls + lies there for a minute
local BILLS: ClientVFXType.Scatter = table.freeze({
	Limb = "RightHand",
	Count = 5,
	Size = Vector3.new(2, 0.4, 1),
	Color = BrickColor.new("Dark green").Color,
	Decal = "Bill" :: "Bill",
	Reach = 2,
	Rise = 4,
	Lifetime = 60,
})
-- Variables
local random = Random.new()
-- References
-- Private Functions
local function newSound(sound: SoundKey): ClientVFXType.Sound
	return table.freeze({ Sound = sound })
end
-- Class
-- one of these is heard with every throw, whichever
local SOUNDS: { ClientVFXType.Sound } =
	table.freeze({ newSound("Moneybag1"), newSound("Moneybag2"), newSound("Moneybag3") })
local definitionRes = PropDefinition.get(ID)
assert(definitionRes.IsOk, `no prop is registered as "{ID}"`)

-- a bag out of the vault of the bank: a click throws a handful of bills about. it pays nothing + never did, the
-- money of the vault is the pad beside it. the bills are drawn by whoever sees them: the old ones were parts of the
-- server that anybody could stand on
return table.freeze({
	Prop = definitionRes.Value,
	Look = LOOK,
	HoldAnimation = HOLD_ANIMATION,
	Bills = BILLS,
	getSound = function(): ClientVFXType.Sound
		return SOUNDS[random:NextInteger(1, #SOUNDS)]
	end,
})
