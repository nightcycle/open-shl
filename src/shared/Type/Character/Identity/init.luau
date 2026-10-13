--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
-- Hooks
-- Types
local AppearanceType = require("@self/Appearance")
local Types = {}

type Appearance = AppearanceType.Appearance

export type PowerSkin = {
	Id: string,
	ColorGroups: {
		Primary: Color3?,
	},
}
Types.PowerSkin = Type.strictInterface({
	Id = Type.string,
	ColorGroups = Type.strictInterface({
		Primary = Type.optional(Type.Color3),
	}),
})

export type Identity = {
	Profile: {
		Name: string,
		Backstory: string,
		Alignment: PseudoEnum.Alignment,
	},
	PowerSkins: {
		[string]: PowerSkin,
	},
	Appearance: Appearance,
}
Types.Identity = Type.strictInterface({
	Profile = Type.strictInterface({
		Name = Type.string,
		Backstory = Type.string,
		Alignment = Type.literal(table.unpack(PseudoEnum.getEnumItems("Alignment"))),
	}),
	PowerSkins = Type.map(Type.string, Types.PowerSkin),
	Appearance = AppearanceType.Appearance,
})

return Types
