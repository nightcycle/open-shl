--!strict
-- Services
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
-- Packages
-- Modules
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
type SoundKey = VFXAssetDefinition.SoundKey
-- Constants
local MAX_DISTANCE = 150
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- a sound coming from the avatar that's already playing. nil for an avatar that isn't there to make it
Module.play = function(character: Model?, key: SoundKey, isLooped: boolean): Sound?
	local source = character and character.PrimaryPart
	if not source then
		return nil
	end
	local definition = VFXAssetDefinition.getSound(key)
	local sound = Instance.new("Sound")
	sound.Name = key
	sound.SoundId = definition.Url
	sound.Volume = definition.Volume
	sound.PlaybackSpeed = definition.PlaybackSpeed
	sound.Looped = isLooped
	sound.RollOffMaxDistance = MAX_DISTANCE
	sound.Parent = source
	if RunService:IsRunning() then
		sound:Play()
	else
		-- nothing plays in the world of a place that isn't running, a story is heard this way
		SoundService:PlayLocalSound(sound)
	end
	return sound
end

return Module
