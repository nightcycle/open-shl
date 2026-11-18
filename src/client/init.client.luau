--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local ServiceDefinition = require("@game/StarterPlayer/StarterPlayerScripts/Client/Definition/Service")
-- Components
local App = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/App/Container/App")
-- Types
type Service = ServiceLocker.InitializationInterface
-- Constants
-- Variables
local Services: { Service } = {}
local DestroyCallbacks: { () -> () } = {}
-- References
local PlayerGui = IndexUtil.waitForLocalPath(Players.LocalPlayer, "PlayerGui")
-- Private Functions
local e = React.createElement
-- Class
-- every one of this game's is in before the first starts
for _, entry in ServiceDefinition.list() do
	table.insert(Services, entry.Load())
end
-- on a private server what the game plays by is the server's to say, everything below asks about it
ModeDefinition.await()
-- in the order of the list
for _, service in Services do
	table.insert(DestroyCallbacks, service.init())
end

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
	for index = #DestroyCallbacks, 1, -1 do
		DestroyCallbacks[index]()
	end
end)

-- what a play-test looks for: every service is up + the app is on its way to the screen
print(`[boot] client ok ({GameDefinition.ID})`)
