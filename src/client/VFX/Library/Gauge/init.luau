--!strict
-- Services
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Components
local AmmoBar = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/AmmoBar")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Gauge
-- Constants
local GUI_NAME = "Gauge"
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function getGuiParent(): Instance?
	local player = Players.LocalPlayer
	if player then
		return player:FindFirstChildOfClass("PlayerGui")
	end
	-- a place that isn't running has no player to put the bar in front of, a story gets it this way
	return if RunService:IsRunning() then nil else CoreGui
end
-- Class
return ClientVFX.state(ClientVFXDefinition.Gauge, function(props: Properties, scope: ClientScope)
	local guiParent = getGuiParent()
	-- what somebody else holds isn't counted on this screen
	if not scope.IsOwner or not guiParent then
		return function() end
	end
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = GUI_NAME
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = guiParent
	local root = ReactRoblox.createRoot(screenGui)
	local shownCount: number? = nil
	local shownText: string? = nil

	-- the bar is only drawn anew once what's read isn't what it shows
	local function draw()
		local count, text = props.Read()
		if count == shownCount and text == shownText then
			return
		end
		shownCount, shownText = count, text
		root:render(e(
			AmmoBar,
			{
				Size = UDim2.fromScale(1, 1),
				Caption = props.Caption,
				Count = count,
				Max = props.Max,
				Text = text,
			} :: AmmoBar.Properties
		))
	end

	draw()
	local connection = RunService.Heartbeat:Connect(draw)
	return function()
		connection:Disconnect()
		root:unmount()
		screenGui:Destroy()
	end
end)
