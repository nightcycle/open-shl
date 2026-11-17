--!strict
-- Services
local SoundService = game:GetService("SoundService")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
-- Modules
local SongDefinition = require("@game/ReplicatedStorage/Shared/Definition/Song")
-- Types
type Signal<T...> = Signal.Signal<T...>
export type SongDefinition = SongDefinition.SongDefinition
type MusicServiceImpl = {
	__index: MusicServiceImpl,
	GetSong: (self: MusicService) -> SongDefinition,
	GetIsOn: (self: MusicService) -> boolean,
	SetIsOn: (self: MusicService, isOn: boolean) -> (),
	Next: (self: MusicService) -> (),
	Previous: (self: MusicService) -> (),
}
export type MusicService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		SongChanged: Signal<SongDefinition>,
		PowerChanged: Signal<boolean>, -- the music was turned on or off
		_Song: SongDefinition,
		_IsOn: boolean,
		_Folder: Folder,
		_Sounds: { [string]: Sound },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: MusicServiceImpl
))
-- Constants
local FOLDER_NAME = "Music"
-- Variables
-- References
-- Private Functions
-- a song gets a sound of its own the first time it's up, so the end of one is never mistaken for the end of another
local function getSound(self: MusicService, song: SongDefinition): Sound
	local cached = self._Sounds[song.Id]
	if cached then
		return cached
	end
	local sound = Instance.new("Sound")
	sound.Name = song.Id
	sound.SoundId = song.SoundId
	sound.Volume = song.Volume
	sound.Looped = false
	sound.Parent = self._Folder
	self._Sounds[song.Id] = sound

	-- a sound that was stopped doesn't fire Ended
	table.insert(
		self._Connections,
		sound.Ended:Connect(function()
			if not self._IsOn or self._Song.Id ~= song.Id then
				return
			end
			-- a song that never loaded fires Ended right away
			if sound.TimeLength <= 0 then
				return
			end
			self:Next()
		end)
	)
	return sound
end

local function setSong(self: MusicService, song: SongDefinition)
	if self._Song.Id == song.Id then
		return
	end
	local previous = self._Sounds[self._Song.Id]
	if previous then
		previous:Stop()
	end
	self._Song = song
	if self._IsOn then
		getSound(self, song):Play()
	end
	self.SongChanged:Fire(song)
end
-- Class
local MusicService = {} :: MusicServiceImpl
MusicService.__index = MusicService

function MusicService:GetSong(): SongDefinition
	return self._Song
end

function MusicService:GetIsOn(): boolean
	return self._IsOn
end

-- on plays the song from its start, there's no pause
function MusicService:SetIsOn(isOn: boolean)
	if self._IsOn == isOn then
		return
	end
	self._IsOn = isOn
	if isOn then
		getSound(self, self._Song):Play()
	else
		local sound = self._Sounds[self._Song.Id]
		if sound then
			sound:Stop()
		end
	end
	self.PowerChanged:Fire(isOn)
end

function MusicService:Next()
	local songRes = SongDefinition.getNext(self._Song.Id)
	if songRes.IsErr then
		warn(`song err: {songRes.Value}`)
		return
	end
	setSong(self, songRes.Value)
end

function MusicService:Previous()
	local songRes = SongDefinition.getPrevious(self._Song.Id)
	if songRes.IsErr then
		warn(`song err: {songRes.Value}`)
		return
	end
	setSong(self, songRes.Value)
end

return ServiceLocker(function(): MusicService
	local songRes = SongDefinition.get(SongDefinition.DEFAULT_ID)
	assert(songRes.IsOk, `the default song isn't defined`)

	-- outside of the interface + the avatar, so the music plays on while the panel is closed + across respawns
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = SoundService

	local self = setmetatable({
		IsInitialized = true :: true,
		SongChanged = Signal.new(),
		PowerChanged = Signal.new(),
		_Song = songRes.Value,
		_IsOn = false, -- silent until the player opts in
		_Folder = folder,
		_Sounds = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, MusicService)

	table.insert(self._CleanUpCallbacks, function()
		folder:Destroy()
	end)

	return self
end, function(self: MusicService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	self.SongChanged:Destroy()
	self.PowerChanged:Destroy()
	table.clear(self :: any)
end)
