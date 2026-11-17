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
local Types = {}

export type PublicProfile = {
	UserId: number,
	UserName: string,
	AliasName: string, -- the name of the super identity, "" when it's unset or kept private
	IdentityName: string, -- the name of the secret identity, "" when it's unset or kept private
	Alignment: PseudoEnum.Alignment,
	Backstory: string, -- "" when it's unset
}
Types.PublicProfile = Type.strictInterface({
	UserId = Type.integer,
	UserName = Type.string,
	AliasName = Type.string,
	IdentityName = Type.string,
	Alignment = Type.literal(table.unpack(PseudoEnum.getEnumItems("Alignment"))),
	Backstory = Type.string,
})

return Types
