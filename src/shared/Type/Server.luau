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

-- every mode is a place of its own, built with the switches of that mode
export type Mode = "roleplay" | "combat"
Types.Mode = Type.literal("roleplay", "combat")

-- what the browser shows of a custom server, its entry code never leaves the server
export type Listing = {
	Id: string,
	Name: string,
	OwnerName: string,
	Region: string, -- the country code of whoever made it, "" when there's none to go by
	IsLocked: boolean, -- takes an entry code to get in
	IsPVP: boolean,
	Fill: number,
	Limit: number,
}
Types.Listing = Type.strictInterface({
	Id = Type.string,
	Name = Type.string,
	OwnerName = Type.string,
	Region = Type.string,
	IsLocked = Type.boolean,
	IsPVP = Type.boolean,
	Fill = Type.integer,
	Limit = Type.integer,
})

-- what the form a custom server is made with asks for
export type Settings = {
	Name: string,
	Limit: number,
	Code: string, -- "" leaves the server open to anybody
	IsPVP: boolean,
}
Types.Settings = Type.strictInterface({
	Name = Type.string,
	Limit = Type.number,
	Code = Type.string,
	IsPVP = Type.boolean,
})

-- a try at getting into a custom server
export type Entry = {
	Id: string,
	Code: string, -- "" when the player wasn't asked for one
}
Types.Entry = Type.strictInterface({
	Id = Type.string,
	Code = Type.string,
})

return Types
