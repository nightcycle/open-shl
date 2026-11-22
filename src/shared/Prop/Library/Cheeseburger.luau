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
local ID = "cheeseburger"
-- of the hand from the burger, the way the old tool gripped it: out in front
local REST_GRIP = CFrame.new(0.669, -0.115, 0.011, 0, 1, 0, 0, 0, -1, -1, 0, 0)
-- up at the mouth for as long as a bite takes
local BITE_GRIP = CFrame.new(-0.338, -0.648, -1.489, 0, 0.981, -0.196, 0, -0.196, -0.981, -1, 0, 0)
local SIZE = Vector3.new(1, 0.8, 1)
-- the mesh is drawn by its texture, the part under it never shows
local COLOR = Color3.new(1, 1, 1)
local REST: ClientVFXType.Prop = {
	Limb = "RightHand",
	Size = SIZE,
	Offset = REST_GRIP,
	Color = COLOR,
	Mesh = "Cheeseburger",
}
table.freeze(REST)
local BITE: ClientVFXType.Prop = {
	Limb = "RightHand",
	Size = SIZE,
	Offset = BITE_GRIP,
	Color = COLOR,
	Mesh = "Cheeseburger",
}
table.freeze(BITE)
local HOLD_ANIMATION: AnimationKey = "GunHolding"
-- the wrapper coming off as it's got out, then every bite
local DRAW_SOUND: SoundKey = "CheeseburgerOpen"
local BITE_SOUND: SoundKey = "CheeseburgerBite"
-- what a bite that's finished gives back. the health everybody gets by themselves is half as quick
local BITE_HEALTH = 1.6
-- Variables
-- References
-- Private Functions
-- Class
local definitionRes = PropDefinition.get(ID)
assert(definitionRes.IsOk, `no prop is registered as "{ID}"`)
assert(definitionRes.Value.Use, `"{ID}" is eaten a bite at a time, its row says how long one takes`)

-- a burger off a picnic table: a click is a bite, a bite that's finished is a little health
return table.freeze({
	Prop = definitionRes.Value,
	Rest = REST,
	Bite = BITE,
	HoldAnimation = HOLD_ANIMATION,
	DrawSound = DRAW_SOUND,
	BiteSound = BITE_SOUND,
	BiteHealth = BITE_HEALTH,
})
