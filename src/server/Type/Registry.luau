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

-- what the memory store holds of a custom server. the server it was made on writes it once, from then on the custom
-- server keeps it alive itself
export type CustomServer = {
	Id: string, -- its private server id, which is also what a teleport into it is aimed at
	PlaceId: number,
	OwnerId: number,
	OwnerName: string,
	Name: string,
	Code: string, -- "" leaves the server open to anybody
	IsPVP: boolean,
	Region: string, -- the country code of the owner, "" when there's none to go by
	Limit: number,
	Fill: number, -- how many players it held when it last wrote
	AdminIds: { number },
	BannedIds: { number },
}
Types.CustomServer = Type.strictInterface({
	Id = Type.string,
	PlaceId = Type.integer,
	OwnerId = Type.integer,
	OwnerName = Type.string,
	Name = Type.string,
	Code = Type.string,
	IsPVP = Type.boolean,
	Region = Type.string,
	Limit = Type.intersection(Type.integer, Type.numberMin(1)),
	Fill = Type.intersection(Type.integer, Type.numberMin(0)),
	AdminIds = Type.array(Type.integer),
	BannedIds = Type.array(Type.integer),
})

-- where the server behind an id players read out to each other is found
export type PublicServer = {
	PlaceId: number,
	JobId: string,
}
Types.PublicServer = Type.strictInterface({
	PlaceId = Type.integer,
	JobId = Type.string,
})

return Types
