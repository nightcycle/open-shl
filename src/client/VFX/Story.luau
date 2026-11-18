--!strict
-- Services
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Aim = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Aim")
local ClientVFXLibrary = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Library")
local Driver = require("@game/ReplicatedStorage/Shared/VFX/Driver")
local Scope = require("@game/ReplicatedStorage/Shared/VFX/Scope")
-- Types
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type VFX = VFXType.VFX
type Subject = VFXType.Subject
type Swap = VFXType.Swap
type Cleanup = VFXType.Cleanup
-- what a story plays its effects on: a dummy for whoever uses them + one for whoever they're used on, stood in the
-- world of the place in front of the camera
export type Stage = {
	User: Model,
	Target: Model,
	-- both run every kind of effect right here, a story has neither a server nor other clients
	ClientScope: VFXType.ClientScope,
	ServerScope: VFXType.ServerScope,
	-- the scopes for an effect on somebody else
	newClientScope: (character: Model) -> VFXType.ClientScope,
	newServerScope: (character: Model) -> VFXType.ServerScope,
}
export type PanelButton = {
	Text: string,
	IsOn: boolean?,
	OnClick: () -> (),
}
export type PanelProperties = {
	Lines: { string },
	Buttons: { PanelButton },
}
-- Constants
local FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local FOLDER_NAME = "VFXStory"
-- the control of a story that moves its dummies apart
local DISTANCE_CONTROL = "Distance"
-- studs in front of the camera the user stands at
local CAMERA_DISTANCE = 22
local DEFAULT_TARGET_DISTANCE = 6
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function newDummy(name: string, color: Color3, pivot: CFrame, parent: Instance): Model
	local description = Instance.new("HumanoidDescription")
	description.HeadColor = color
	description.TorsoColor = color
	description.LeftArmColor = color
	description.RightArmColor = color
	description.LeftLegColor = color
	description.RightLegColor = color
	local dummy = Players:CreateHumanoidModelFromDescriptionAsync(description, Enum.HumanoidRigType.R15)
	dummy.Name = name
	local rootPart = dummy.PrimaryPart
	if rootPart then
		-- nothing holds it up in a place that isn't running
		rootPart.Anchored = true
	end
	dummy:PivotTo(pivot)
	dummy.Parent = parent
	return dummy
end

-- the one driver of a story: client, shared + server effects all run in place, what the server would have clients
-- show is shown right away
local function newDriver(): VFXType.Driver
	local driver: VFXType.Driver
	driver = Driver.new({
		GetImplementation = ClientVFXLibrary.get,
		RunsServer = true,
		FireClient = function(vfx: VFX, props: unknown, subject: Subject)
			driver.Fire(vfx, props, subject)
		end,
		StartClient = function(vfx: VFX, props: unknown, subject: Subject, swap: Swap?): Cleanup?
			return driver.Start(vfx, props, subject, swap)
		end,
	})
	return driver
end
-- Class
local Module = {}

-- yields while the dummies are made. what it hands back with the stage takes all of it down again
Module.newStage = function(targetDistance: number?): (Stage, () -> ())
	local camera = Workspace.CurrentCamera
	local cameraCFrame = if camera then camera.CFrame else CFrame.new(0, 20, 0)
	local look = cameraCFrame.LookVector * Vector3.new(1, 0, 1)
	local forward = if look.Magnitude > 0.01 then look.Unit else Vector3.zAxis
	local middle = cameraCFrame.Position + forward * CAMERA_DISTANCE
	local right = forward:Cross(Vector3.yAxis)
	local distance = targetDistance or DEFAULT_TARGET_DISTANCE
	local userPosition = middle - right * distance / 2
	local targetPosition = middle + right * distance / 2

	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	-- whatever is left in the camera is neither saved with the place nor synced anywhere
	folder.Parent = camera or Workspace
	local user = newDummy("User", Color3.fromRGB(90, 160, 255), CFrame.lookAt(userPosition, targetPosition), folder)
	local target = newDummy("Target", Color3.fromRGB(255, 110, 90), CFrame.lookAt(targetPosition, userPosition), folder)
	-- a story has no mouse to point with, the user aims at the target
	Aim.setOverride(target:GetPivot().Position)

	local driver = newDriver()
	local function newScope(character: Model): any
		local scope = Scope.new(
			table.freeze({
				Character = character,
				Player = nil,
				IsOwner = true,
			}),
			driver
		)
		return scope
	end
	local stage: Stage = table.freeze({
		User = user,
		Target = target,
		ClientScope = newScope(user),
		ServerScope = newScope(user),
		newClientScope = newScope,
		newServerScope = newScope,
	})
	return stage, function()
		Aim.setOverride(nil)
		folder:Destroy()
	end
end

-- the stage of a story, nil until its dummies are there. it's built anew whenever the distance changes
Module.useStage = function(targetDistance: number?): Stage?
	local stage, setStage = React.useState(nil :: Stage?)
	React.useEffect(function()
		local isCanceled = false
		local destroy: (() -> ())? = nil
		task.spawn(function()
			local newStage, destroyStage = Module.newStage(targetDistance)
			if isCanceled then
				destroyStage()
				return
			end
			destroy = destroyStage
			setStage(newStage)
		end)
		return function()
			isCanceled = true
			setStage(nil :: any)
			if destroy then
				destroy()
			end
		end
	end, { targetDistance :: any })
	return stage
end

-- what a story shows in its own frame: a few lines on what's going on + a button for everything there is to set off.
-- the effects themselves are out in the world of the place
Module.Panel = function(props: PanelProperties)
	local children: { [string]: any } = {
		UIListLayout = e("UIListLayout", {
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		UIPadding = e("UIPadding", {
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 10),
		}),
	}
	for index, line in props.Lines do
		children[`Line{index}`] = e("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			FontFace = FONT,
			LayoutOrder = index,
			Size = UDim2.fromScale(1, 0),
			Text = line,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 16,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end
	for index, button in props.Buttons do
		children[`Button{index}`] = e("TextButton", {
			BackgroundColor3 = if button.IsOn then Color3.fromRGB(0, 140, 60) else Color3.fromRGB(60, 60, 60),
			FontFace = FONT,
			LayoutOrder = #props.Lines + index,
			Size = UDim2.new(1, 0, 0, 30),
			Text = button.Text,
			TextColor3 = Color3.new(1, 1, 1),
			TextSize = 16,
			[React.Event.Activated] = button.OnClick,
		})
	end
	return e("Frame", {
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundColor3 = Color3.new(),
		BackgroundTransparency = 0.3,
		Position = UDim2.fromOffset(10, 10),
		Size = UDim2.fromOffset(300, 0),
	}, children)
end

-- a string that changes whenever a control does, for an effect to be run again by. the distance isn't in it: a
-- change of it brings a new stage, which runs the effect again by itself
local function getKey(controls: { [string]: unknown }): string
	local names: { string } = {}
	for name in controls do
		if name ~= DISTANCE_CONTROL then
			table.insert(names, name)
		end
	end
	table.sort(names)
	local key = ""
	for _, name in names do
		key ..= `{name}={controls[name]};`
	end
	return key
end

-- the story of an effect that's fired: it goes off as the stage is up, with every change of a control + at the
-- press of the button. a Distance control moves the two dummies apart
Module.newEventStory = function(controls: { [string]: any }, fire: (stage: Stage, controls: any) -> ())
	return UILabs.CreateReactStory({
		react = React,
		reactRoblox = ReactRoblox,
		controls = controls,
	}, function(props)
		local stage = Module.useStage(props.controls.Distance)
		local count, setCount = React.useState(0)
		React.useEffect(function()
			-- a stage that's on its way out is still handed over once, its dummies are gone by then
			if stage and stage.User.Parent then
				fire(stage, props.controls)
			end
		end, { stage :: any, count, getKey(props.controls) })
		return e(Module.Panel, {
			Lines = { if stage then "the effect plays on the dummies in the place" else "setting the stage.." },
			Buttons = {
				{
					Text = "Fire",
					OnClick = function()
						setCount(count + 1)
					end,
				},
			},
		})
	end)
end

-- the story of an effect that's held: it's on for as long as the button says + is started over with every change
-- of a control
Module.newStateStory = function(controls: { [string]: any }, start: (stage: Stage, controls: any) -> Cleanup)
	return UILabs.CreateReactStory({
		react = React,
		reactRoblox = ReactRoblox,
		controls = controls,
	}, function(props)
		local stage = Module.useStage(props.controls.Distance)
		local isOn, setIsOn = React.useState(true)
		React.useEffect(function()
			if stage and stage.User.Parent and isOn then
				local cleanup = start(stage, props.controls)
				return function()
					cleanup(nil)
				end
			end
			return function() end
		end, { stage :: any, isOn, getKey(props.controls) })
		return e(Module.Panel, {
			Lines = { if stage then "the effect plays on the dummies in the place" else "setting the stage.." },
			Buttons = {
				{
					Text = if isOn then "Stop" else "Start",
					IsOn = isOn,
					OnClick = function()
						setIsOn(not isOn)
					end,
				},
			},
		})
	end)
end

return Module
