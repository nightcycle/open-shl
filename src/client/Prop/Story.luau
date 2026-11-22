--!strict
-- Services
local RunService = game:GetService("RunService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local Aim = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Aim")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Runner = require("@game/ReplicatedStorage/Shared/Prop/Runner")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
type Runner = Runner.Runner
export type Stage = VFXStory.Stage
type Memory = AbilityType.Memory
type ClientContext = PropType.ClientContext
type ServerContext = PropType.ServerContext
type ClientDefinition = PropType.ClientDefinition
type ServerDefinition = PropType.ServerDefinition
-- both halves of a prop running on the user of a stage, wired to each other the way the network would
type Rig = {
	Client: Runner,
	Server: Runner,
	Destroy: () -> (),
}
-- Constants
local READOUT_INTERVAL = 0.2
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function newRig(stage: Stage, client: ClientDefinition, server: ServerDefinition): Rig
	local id = client.Prop.Id
	local serverRunner = Runner.new(server, {
		NewContext = function(aim: AbilityType.Aim?, memory: Memory, record: Memory): ServerContext
			return table.freeze({
				PropId = id,
				Character = stage.User,
				Aim = aim,
				Memory = memory,
				Record = record,
				VFX = stage.ServerScope,
			})
		end,
	})
	local clientRunner = Runner.new(client, {
		NewContext = function(aim: AbilityType.Aim?, memory: Memory, record: Memory): ClientContext
			return table.freeze({
				PropId = id,
				Character = stage.User,
				Aim = aim,
				Memory = memory,
				Record = record,
				VFX = stage.ClientScope,
				getAim = function(): AbilityType.Aim
					return Aim.get(stage.User)
				end,
			})
		end,
		-- the server hears of a click before anything of it shows here
		OnUsed = function(aim: AbilityType.Aim?)
			serverRunner:Use(aim)
		end,
	})
	return {
		Client = clientRunner,
		Server = serverRunner,
		Destroy = function()
			clientRunner:Destroy()
			serverRunner:Destroy()
		end,
	}
end

local function getReadout(rig: Rig, stage: Stage): { string }
	local wait = math.max(0, rig.Server._NextUseTime - os.clock())
	return {
		`client: {if rig.Client.IsHeld then "held" else "put away"}{if rig.Client.IsUsing then ", in use" else ""}`
			.. `   server: {if rig.Server.IsHeld then "held" else "put away"}`
			.. `{if rig.Server.IsUsing then ", in use" else ""}`,
		`next use in: {string.format("%.1f", wait)} s`,
		`user health: {AttributeDefinition.get(stage.User, AttributeDefinition.Health)}`,
	}
end
-- Class
local Module = {}

-- the story of a prop: both halves run on a dummy, wired to each other, so every moment of it can be watched + tuned
-- in the place. a prop has the one story: its buttons are what a hand does with it, the cuffs are there for the arm
Module.new = function(client: ClientDefinition, server: ServerDefinition)
	local prop = client.Prop
	assert(server.Prop.Id == prop.Id, `"{prop.Id}" + "{server.Prop.Id}" aren't the halves of one prop`)

	return UILabs.CreateReactStory({
		react = React,
		reactRoblox = ReactRoblox,
		controls = {
			Health = UILabs.Slider(50, 1, AttributeDefinition.MAX_HEALTH, 1),
		},
	}, function(props)
		local stage = VFXStory.useStage()
		local rig, setRig = React.useState(nil :: Rig?)
		local readout, setReadout = React.useState({} :: { string })
		React.useEffect(function()
			if not stage then
				return function() end
			end
			AttributeDefinition.setDefaults(stage.User, "Character")
			local newStageRig = newRig(stage, client, server)
			setRig(newStageRig)
			local elapsed = 0
			local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
				elapsed += deltaTime
				if elapsed >= READOUT_INTERVAL then
					elapsed = 0
					setReadout(getReadout(newStageRig, stage))
				end
			end)
			return function()
				connection:Disconnect()
				setRig(nil :: any)
				newStageRig.Destroy()
			end
		end, { stage })
		-- what a use gives back is only seen on somebody who's hurt
		React.useEffect(function()
			if stage and stage.User.Parent then
				AttributeDefinition.set(stage.User, AttributeDefinition.Health, props.controls.Health)
			end
		end, { stage :: any, props.controls.Health })

		if not stage or not rig then
			return e(VFXStory.Panel, { Lines = { "setting the stage.." }, Buttons = {} })
		end
		local isCuffed = AttributeDefinition.get(stage.User, AttributeDefinition.IsHandcuffed)
		local buttons: { VFXStory.PanelButton } = {
			{
				Text = "draw",
				IsOn = rig.Client.IsHeld,
				OnClick = function()
					rig.Server:Draw()
					rig.Client:Draw()
				end,
			},
		}
		if prop.Use then
			table.insert(buttons, {
				Text = "use",
				IsOn = rig.Client.IsUsing,
				OnClick = function()
					rig.Client:Use(Aim.get(stage.User))
				end,
			})
		end
		table.insert(buttons, {
			Text = "put away",
			OnClick = function()
				rig.Server:Stow()
				rig.Client:Stow()
			end,
		})
		table.insert(buttons, {
			Text = `cuffed: {if isCuffed then "on" else "off"}`,
			IsOn = isCuffed,
			OnClick = function()
				AttributeDefinition.set(stage.User, AttributeDefinition.IsHandcuffed, not isCuffed)
			end,
		})
		local lines = { `{prop.Name} ({prop.Id})` }
		table.move(readout, 1, #readout, 2, lines)
		return e(VFXStory.Panel, { Lines = lines, Buttons = buttons })
	end)
end

return Module
