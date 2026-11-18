--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type EntitlementKey = EconomyType.EntitlementKey
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

-- what a game offers + how many of them a character carries, without the pass + with it, and which entitlement that
-- pass hands out. the groups are in the order the editor lists them
export type PowerCatalogue = {
	Groups: { PowerGroup },
	Definitions: { PowerDefinition },
	Upcoming: { PowerDefinition }?, -- the ones whose ability isn't built yet, nobody is offered one of them
	DefaultLimit: number,
	PassLimit: number,
	PassEntitlement: EntitlementKey,
}
Types.PowerCatalogue = Type.strictInterface({
	Groups = Type.array(Types.PowerGroup),
	Definitions = Type.array(Types.PowerDefinition),
	Upcoming = Type.optional(Type.array(Types.PowerDefinition)),
	DefaultLimit = Type.intersection(Type.integer, Type.numberPositive),
	PassLimit = Type.intersection(Type.integer, Type.numberPositive),
	PassEntitlement = EconomyType.EntitlementKey,
})

return Types
