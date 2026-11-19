--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local Audio = require("@game/ReplicatedStorage/Generated/Audio")
-- Types
type Result<V, E> = TypeUnionLib.Result<V, E>
local SongType = require("@game/ReplicatedStorage/Shared/Type/Song")
export type SongId = SongType.SongId
export type SongDefinition = SongType.SongDefinition
-- Constants
local ARTIST = "DJ Solaur"
local VOLUME = 0.25
local DEFAULT_ID: SongId = "Danger"
-- assets are owned by the old place
local DEFINITIONS: { SongDefinition } = {
	{
		Id = "Conflict",
		Title = "Conflict",
		Artist = ARTIST,
		SoundId = Audio["shl-2"].music["conflict.ogg"],
		Volume = VOLUME,
	},
	{
		Id = "Creator",
		Title = "Creator",
		Artist = ARTIST,
		SoundId = Audio["shl-2"].music["creator.ogg"],
		Volume = VOLUME,
	},
	{ Id = "Damage", Title = "Damage", Artist = ARTIST, SoundId = Audio["shl-2"].music["damage.ogg"], Volume = VOLUME },
	{ Id = "Danger", Title = "Danger", Artist = ARTIST, SoundId = Audio["shl-2"].music["danger.ogg"], Volume = VOLUME },
	{
		Id = "Deliberation",
		Title = "Deliberation",
		Artist = ARTIST,
		SoundId = Audio["shl-2"].music["deliberation.ogg"],
		Volume = VOLUME,
	},
	{
		Id = "Passionate",
		Title = "Passionate",
		Artist = ARTIST,
		SoundId = Audio["shl-2"].music["passionate.ogg"],
		Volume = VOLUME,
	},
	{
		Id = "Sentinel",
		Title = "Sentinel",
		Artist = ARTIST,
		SoundId = Audio["shl-2"].music["sentinel.ogg"],
		Volume = VOLUME,
	},
	{
		Id = "Struggle",
		Title = "Struggle",
		Artist = ARTIST,
		SoundId = Audio["shl-2"].music["struggle.ogg"],
		Volume = VOLUME,
	},
	{
		Id = "Trailblazer",
		Title = "Trailblazer",
		Artist = ARTIST,
		SoundId = Audio["shl-2"].music["trailblazer.ogg"],
		Volume = VOLUME,
	},
	{
		Id = "WindyDay",
		Title = "Windy Day",
		Artist = ARTIST,
		SoundId = Audio["shl-2"].music["windy-day.ogg"],
		Volume = VOLUME,
	},
}
TableUtil.deepFreeze(DEFINITIONS)
-- Variables
-- References
-- Private Functions
local function getIndex(id: string): number?
	for index, definition in DEFINITIONS do
		if definition.Id == id then
			return index
		end
	end
	return nil
end

-- Class
local Module = {}

for _, DEFINITION in DEFINITIONS do
	assert(SongType.SongDefinition(DEFINITION))
end

Module.DEFAULT_ID = DEFAULT_ID

Module.get = function(id: string): Result<SongDefinition, string>
	local index = getIndex(id)
	if index == nil then
		return Result.err(`no song "{id}"`)
	end
	return Result.ok(DEFINITIONS[index])
end

-- the list wraps around at both ends
Module.getNext = function(id: string): Result<SongDefinition, string>
	local index = getIndex(id)
	if index == nil then
		return Result.err(`no song "{id}"`)
	end
	return Result.ok(DEFINITIONS[index % #DEFINITIONS + 1])
end

Module.getPrevious = function(id: string): Result<SongDefinition, string>
	local index = getIndex(id)
	if index == nil then
		return Result.err(`no song "{id}"`)
	end
	return Result.ok(DEFINITIONS[(index - 2) % #DEFINITIONS + 1])
end

Module.list = function(): { SongDefinition }
	return DEFINITIONS
end

return Module
