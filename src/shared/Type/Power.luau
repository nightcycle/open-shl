--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type IconDefinition = MiscType.IconDefinition

local Types = {}

export type PowerGroup = "basic-melee" | "advanced-melee" | "ranged" | "transportation" | "special"
Types.PowerGroup = Type.literal("basic-melee", "advanced-melee", "ranged", "transportation", "special")

export type PowerColorGroupDefinition = {
	Caption: string,
	Default: Color3,
	Choices: { Color3 },
}
Types.PowerColorGroupDefinition = Type.strictInterface({
	Caption = Type.string,
	Default = Type.Color3,
	Choices = Type.array(Type.Color3),
})

export type PowerDefinition = {
	Id: string,
	Group: PowerGroup,
	Name: string,
	Icon: IconDefinition,
	EnergyCost: number,
	Damage: number,
	ColorGroups: { -- keyed like PowerSkin.ColorGroups
		Primary: PowerColorGroupDefinition?,
	},
}
Types.PowerDefinition = Type.strictInterface({
	Id = Type.string,
	Group = Types.PowerGroup,
	Name = Type.string,
	Icon = MiscType.IconDefinition,
	EnergyCost = Type.number,
	Damage = Type.number,
	ColorGroups = Type.strictInterface({
		Primary = Type.optional(Types.PowerColorGroupDefinition),
	}),
})

return Types
