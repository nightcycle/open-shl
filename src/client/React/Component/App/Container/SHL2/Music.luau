--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local MusicService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Music")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Components
local MusicPlayer = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/MusicPlayer")
-- Hooks
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
-- Types
type SongDefinition = MusicService.SongDefinition
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(): React.ReactNode
	assert(MusicService.IsInitialized, `the music service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local song = useSignalState(MusicService.SongChanged, function(): SongDefinition
		return MusicService:GetSong()
	end)
	local isOn = useSignalState(MusicService.PowerChanged, function(): boolean
		return MusicService:GetIsOn()
	end)

	return e(
		MusicPlayer,
		{
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.3, 0.08),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			Song = song,
			IsOn = isOn,
			OnAction = function(action: MusicPlayer.ActionInfo)
				if action.Type == "SetPower" then
					MusicService:SetIsOn(action.IsOn)
				elseif action.Type == "Next" then
					MusicService:Next()
				elseif action.Type == "Previous" then
					MusicService:Previous()
				elseif action.Type == "Exit" then
					ShellService:ClosePanel("Music")
				end
			end,
		} :: MusicPlayer.Properties
	)
end
