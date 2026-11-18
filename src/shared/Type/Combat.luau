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

-- how somebody who's hit is sent off: at this pace along whichever of the two flat axes they're further off on, the
-- other one in proportion
export type Knockback = {
	Speed: number, -- studs a second
	Duration: number, -- seconds they're kept at it
	MaxForce: Vector3, -- what the mover that keeps them at it may push with
	Power: number, -- how hard that mover goes after the pace
}
Types.Knockback = Type.strictInterface({
	Speed = Type.numberPositive,
	Duration = Type.numberPositive,
	MaxForce = Type.Vector3,
	Power = Type.numberPositive,
})

-- the health everybody who's up + hurt gets back by themselves
export type Regeneration = {
	Amount: number, -- health
	Interval: number, -- seconds
}
Types.Regeneration = Type.strictInterface({
	Amount = Type.numberPositive,
	Interval = Type.numberPositive,
})

-- what a game makes of one character hitting another
export type CombatRule = {
	PlayerScale: number, -- what a hit on somebody's character is multiplied by
	IsMenuSafe: boolean, -- nobody is hurt while they sit in a menu
	Knockback: Knockback?, -- nobody is sent off without
	Regeneration: Regeneration?, -- health only comes back by a power without
}
Types.CombatRule = Type.strictInterface({
	PlayerScale = Type.numberPositive,
	IsMenuSafe = Type.boolean,
	Knockback = Type.optional(Types.Knockback),
	Regeneration = Type.optional(Types.Regeneration),
})

return Types
