--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
type EntitlementKey = EconomyType.EntitlementKey
type IconDefinition = MiscType.IconDefinition
type IdentityKey = CharacterType.IdentityKey

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

-- one of the places a character has a power in, it holds one of its list at most. a power that isn't built yet is
-- listed where it's going to be
export type PowerSlot = {
	Key: string,
	Caption: string, -- what the editor calls it
	PowerIds: { string }, -- in the order the editor walks them
}
Types.PowerSlot = Type.strictInterface({
	Key = Type.string,
	Caption = Type.string,
	PowerIds = Type.array(Type.string),
})

-- what a game offers + how many of them a character carries, without the pass + with it, and which entitlement that
-- pass hands out: a game whose limit no pass raises names none. the groups are in the order the editor lists them
export type PowerCatalogue = {
	Groups: { PowerGroup },
	Definitions: { PowerDefinition },
	Upcoming: { PowerDefinition }?, -- the ones whose ability isn't built yet, nobody is offered one of them
	Slots: { PowerSlot }?, -- a character takes any of the game's powers up to its limit without
	IdentityKey: IdentityKey?, -- the one identity that carries the powers, every one of them does without
	DefaultLimit: number,
	PassLimit: number,
	PassEntitlement: EntitlementKey?,
}
Types.PowerCatalogue = Type.intersection(
	Type.strictInterface({
		Groups = Type.array(Types.PowerGroup),
		Definitions = Type.array(Types.PowerDefinition),
		Upcoming = Type.optional(Type.array(Types.PowerDefinition)),
		Slots = Type.optional(Type.array(Types.PowerSlot)),
		IdentityKey = Type.optional(CharacterType.IdentityKey),
		DefaultLimit = Type.intersection(Type.integer, Type.numberPositive),
		PassLimit = Type.intersection(Type.integer, Type.numberPositive),
		PassEntitlement = Type.optional(EconomyType.EntitlementKey),
	}),
	-- a limit that's raised is raised by a pass
	function(value: PowerCatalogue): (boolean, string?)
		if value.PassEntitlement == nil and value.PassLimit ~= value.DefaultLimit then
			return false, `a pass limit of its own without the entitlement that hands it out`
		end
		return true
	end
)

return Types
