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

-- how long the two of a hit count as in a fight, who lost health + who took it off them: every loss adds to what's
-- left of the one before
export type Fighting = {
	Duration: number, -- seconds a loss of health adds
	MaxDuration: number, -- seconds it's never further off than
}
Types.Fighting = Type.intersection(
	Type.strictInterface({
		Duration = Type.numberPositive,
		MaxDuration = Type.numberPositive,
	}),
	function(value: Fighting): (boolean, string?)
		if value.Duration > value.MaxDuration then
			return false, `a loss of health adds more than a fight can last`
		end
		return true
	end
)

-- why somebody isn't counted as in a menu although their client says they are
export type MenuRefusal = {
	Type: "Fighting",
	Until: number, -- when the fight is over, on the clock of the server
}
Types.MenuRefusal = Type.strictInterface({
	Type = Type.literal("Fighting"),
	Until = Type.number,
})

-- what a game makes of one character hitting another
export type CombatRule = {
	PlayerScale: number, -- what a hit on somebody's character is multiplied by
	IsMenuSafe: boolean, -- nobody is hurt while they sit in a menu
	IsOptional: boolean?, -- only two who both chose to fight hurt each other, everybody fights without
	IsShieldSafe: boolean?, -- nobody is hurt under the force field their spot handed them, it stops nothing without
	Fighting: Fighting?, -- nobody is kept out of a menu without
	Knockback: Knockback?, -- nobody is sent off without
	Regeneration: Regeneration?, -- health only comes back by a power without
}
Types.CombatRule = Type.intersection(
	Type.strictInterface({
		PlayerScale = Type.numberPositive,
		IsMenuSafe = Type.boolean,
		IsOptional = Type.optional(Type.boolean),
		IsShieldSafe = Type.optional(Type.boolean),
		Fighting = Type.optional(Types.Fighting),
		Knockback = Type.optional(Types.Knockback),
		Regeneration = Type.optional(Types.Regeneration),
	}),
	-- a menu that shelters nobody has nobody to keep out of it
	function(value: CombatRule): (boolean, string?)
		if value.Fighting ~= nil and not value.IsMenuSafe then
			return false, `a fight keeps out of the menus, which shelter nobody without IsMenuSafe`
		end
		return true
	end
)

return Types
