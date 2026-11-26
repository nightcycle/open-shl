--!strict
-- Services
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Components
local Panel = require("@self/Panel")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Spectate
-- Constants
local GUI_NAME = "Spectate"
-- where a story looks at whoever it watches from, counted from the middle of them
local STORY_OFFSET = Vector3.new(0, 2, 10)
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- everybody there is to watch right now, in an order that stays the same from one click to the next
local function getTargets(props: Properties, character: Model?): { Model }
	local candidates: { Model } = {}
	if props.Targets then
		candidates = props.Targets
	else
		for _, player in Players:GetPlayers() do
			if player.Character then
				table.insert(candidates, player.Character)
			end
		end
	end
	local targets: { Model } = {}
	for _, candidate in candidates do
		if candidate ~= character and candidate:FindFirstChildWhichIsA("Humanoid") then
			table.insert(targets, candidate)
		end
	end
	return targets
end

local function getGuiParent(): Instance?
	local player = Players.LocalPlayer
	if player then
		return player:FindFirstChildOfClass("PlayerGui")
	end
	-- a place that isn't running has no player to put the buttons in front of, a story gets them this way
	return if RunService:IsRunning() then nil else CoreGui
end
-- Class
return ClientVFX.state(ClientVFXDefinition.Spectate, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local camera = Workspace.CurrentCamera
	if not camera then
		return function() end
	end
	local isRunning = RunService:IsRunning()
	local initialCFrame = camera.CFrame
	local watched: Model? = nil
	local connection: RBXScriptConnection? = nil

	-- nil hands the camera back to the avatar the effect belongs to
	local function watch(target: Model?)
		watched = target
		if connection then
			connection:Disconnect()
			connection = nil
		end
		if isRunning then
			local subject = target or character
			local humanoid = subject and subject:FindFirstChildWhichIsA("Humanoid")
			-- an avatar that's gone is nothing to hand the camera to, the one that comes after it takes it by itself
			if subject and humanoid and subject:IsDescendantOf(game) then
				camera.CameraType = Enum.CameraType.Custom
				camera.CameraSubject = humanoid
			end
		elseif target then
			-- nothing follows anybody in a place that isn't running, a story is put behind them by hand
			local pivot = target:GetPivot()
			camera.CFrame = CFrame.lookAt(pivot:PointToWorldSpace(STORY_OFFSET), pivot.Position)
		else
			camera.CFrame = initialCFrame
		end
		if target then
			-- an avatar that's gone leaves nothing to look at
			connection = target.AncestryChanged:Connect(function()
				if watched == target and not target:IsDescendantOf(game) then
					watch(nil)
				end
			end)
		end
	end

	local function cycle(direction: number)
		local targets = getTargets(props, character)
		local count = #targets
		if count == 0 then
			if watched then
				watch(nil)
			end
			return
		end
		local index = if watched then table.find(targets, watched) else nil
		if index then
			watch(targets[(index - 1 + direction) % count + 1])
		else
			-- from nobody the way forth starts with the first of them, the way back with the last
			watch(targets[if direction > 0 then 1 else count])
		end
	end

	-- one that's told who to start on doesn't wait for a button
	if props.Index then
		local targets = getTargets(props, character)
		if #targets > 0 then
			watch(targets[(props.Index - 1) % #targets + 1])
		end
	end

	local unmount: (() -> ())? = nil
	local guiParent = if props.IsBare then nil else getGuiParent()
	if guiParent then
		local screenGui = Instance.new("ScreenGui")
		screenGui.Name = GUI_NAME
		screenGui.ResetOnSpawn = false
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.Parent = guiParent
		local root = ReactRoblox.createRoot(screenGui)
		root:render(e(
			Panel,
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.7),
				Size = UDim2.fromScale(0.15, 0.1),
				OnCycle = cycle,
			} :: Panel.Properties
		))
		unmount = function()
			root:unmount()
			screenGui:Destroy()
		end
	end

	return function()
		if unmount then
			unmount()
		end
		-- a camera that was never taken isn't anybody's to hand back
		if watched then
			watch(nil)
		end
	end
end)
