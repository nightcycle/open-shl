--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
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
	{ Id = "Conflict", Title = "Conflict", Artist = ARTIST, SoundId = "rbxassetid://793808482", Volume = VOLUME },
	{ Id = "Creator", Title = "Creator", Artist = ARTIST, SoundId = "rbxassetid://793809203", Volume = VOLUME },
	{ Id = "Damage", Title = "Damage", Artist = ARTIST, SoundId = "rbxassetid://793811063", Volume = VOLUME },
	{ Id = "Danger", Title = "Danger", Artist = ARTIST, SoundId = "rbxassetid://793811660", Volume = VOLUME },
	{
		Id = "Deliberation",
		Title = "Deliberation",
		Artist = ARTIST,
		SoundId = "rbxassetid://793813299",
		Volume = VOLUME,
	},
	{ Id = "Passionate", Title = "Passionate", Artist = ARTIST, SoundId = "rbxassetid://793814041", Volume = VOLUME },
	{ Id = "Sentinel", Title = "Sentinel", Artist = ARTIST, SoundId = "rbxassetid://793814978", Volume = VOLUME },
	{ Id = "Struggle", Title = "Struggle", Artist = ARTIST, SoundId = "rbxassetid://793816038", Volume = VOLUME },
	{ Id = "Trailblazer", Title = "Trailblazer", Artist = ARTIST, SoundId = "rbxassetid://793817162", Volume = VOLUME },
	{ Id = "WindyDay", Title = "Windy Day", Artist = ARTIST, SoundId = "rbxassetid://793817644", Volume = VOLUME },
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
