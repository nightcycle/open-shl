--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
-- Modules
local AbilityService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Ability")
local CameraModeService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/CameraMode")
local EmoteService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Emote")
local MusicService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Music")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local QuestGiverService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/QuestGiver")
local ResidenceService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Residence")
local SessionService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Session")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
local SwapService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Swap")
local VFXService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/VFX")
-- Components
local App = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/App")
-- Types
-- Constants
-- Variables
-- References
local PlayerGui = IndexUtil.waitForLocalPath(Players.LocalPlayer, "PlayerGui")
-- Private Functions
local e = React.createElement
-- Class
-- in dependency order
assert(not NetworkService.IsInitialized, `the network service is already initialized`)
local destroyNetwork = NetworkService.init()
assert(not VFXService.IsInitialized, `the vfx service is already initialized`)
local destroyVFX = VFXService.init()
assert(not AbilityService.IsInitialized, `the ability service is already initialized`)
local destroyAbility = AbilityService.init()
assert(not SessionService.IsInitialized, `the session service is already initialized`)
local destroySession = SessionService.init()
assert(not ShellService.IsInitialized, `the shell service is already initialized`)
local destroyShell = ShellService.init()
assert(not MusicService.IsInitialized, `the music service is already initialized`)
local destroyMusic = MusicService.init()
assert(not CameraModeService.IsInitialized, `the camera mode service is already initialized`)
local destroyCameraMode = CameraModeService.init()
assert(not SwapService.IsInitialized, `the swap service is already initialized`)
local destroySwap = SwapService.init()
assert(not EmoteService.IsInitialized, `the emote service is already initialized`)
local destroyEmote = EmoteService.init()
assert(not ResidenceService.IsInitialized, `the residence service is already initialized`)
local destroyResidence = ResidenceService.init()
assert(not QuestGiverService.IsInitialized, `the quest giver service is already initialized`)
local destroyQuestGiver = QuestGiverService.init()

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "App"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = PlayerGui

local root = ReactRoblox.createRoot(screenGui)
root:render(e(App, {}))

script.Destroying:Connect(function()
	root:unmount()
	screenGui:Destroy()
	destroyQuestGiver()
	destroyResidence()
	destroyEmote()
	destroySwap()
	destroyCameraMode()
	destroyMusic()
	destroyShell()
	destroySession()
	destroyAbility()
	destroyVFX()
	destroyNetwork()
end)
