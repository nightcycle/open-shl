--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local IdentityType = require("@self/Identity")
type Identity = IdentityType.Identity

local Types = {}

export type Power = {
	Id: string,
}
Types.Power = Type.strictInterface({
	Id = Type.string,
})

-- Main is the super identity, Secret is the civilian one
export type IdentityKey = "Main" | "Secret"
Types.IdentityKey = Type.literal("Main", "Secret")

export type Character = {
	Id: string,
	Powers: { Power },
	Identities: {
		Main: Identity,
		[string]: Identity?,
	},
}
Types.Character = Type.strictInterface({
	Id = Type.string,
	Powers = Type.array(Types.Power),
	Identities = Type.intersection(
		Type.interface({
			Main = IdentityType.Identity,
		}),
		Type.map(Type.string, IdentityType.Identity)
	),
})

return Types
