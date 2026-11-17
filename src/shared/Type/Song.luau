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

export type SongId =
	"Conflict"
	| "Creator"
	| "Damage"
	| "Danger"
	| "Deliberation"
	| "Passionate"
	| "Sentinel"
	| "Struggle"
	| "Trailblazer"
	| "WindyDay"
Types.SongId = Type.literal(
	"Conflict",
	"Creator",
	"Damage",
	"Danger",
	"Deliberation",
	"Passionate",
	"Sentinel",
	"Struggle",
	"Trailblazer",
	"WindyDay"
)

export type SongDefinition = {
	Id: SongId,
	Title: string,
	Artist: string,
	SoundId: string,
	Volume: number,
}
Types.SongDefinition = Type.strictInterface({
	Id = Types.SongId,
	Title = Type.string,
	Artist = Type.string,
	SoundId = Type.string,
	Volume = Type.numberConstrained(0, 10),
})

return Types
