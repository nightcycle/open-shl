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
local ConditionStore = require("@game/ReplicatedStorage/Shared/Ability/ConditionStore")
local Context = require("@game/ReplicatedStorage/Shared/Ability/Context")
local Machine = require("@game/ReplicatedStorage/Shared/Ability/Machine")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ConditionStore = ConditionStore.ConditionStore
type Machine = Machine.Machine
export type Stage = VFXStory.Stage
type Condition = AbilityType.Condition
type Requirement = AbilityType.Requirement
type Binding = AbilityType.Binding
type EventBinding = AbilityType.EventBinding
type Stimulus = AbilityType.Stimulus
type Memory = AbilityType.Memory
type ClientDefinition = AbilityType.ClientDefinition
type ServerDefinition = AbilityType.ServerDefinition
export type Options = {
	-- what a binding that's raised rather than triggered is raised with
	GetPayload: ((stage: Stage) -> unknown)?,
	Distance: number?, -- studs between the dummies to start with
}
-- both halves of an ability running on the dummies of a stage, wired to each other the way the network would
type Rig = {
	Client: Machine,
	Server: Machine,
	ClientStore: ConditionStore,
	ServerStore: ConditionStore,
	Destroy: () -> (),
}
-- Constants
-- how long a condition that's flipped to set an event off stays that way
local PULSE_DURATION = 0.15
local READOUT_INTERVAL = 0.2
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function newRig(stage: Stage, client: ClientDefinition, server: ServerDefinition): Rig
	local id = client.Layout.Id
	local clientStore = ConditionStore.new()
	local serverStore = ConditionStore.new()
	local clientMachine: Machine
	local serverMachine: Machine
	local clientSetup: Context.ClientSetup = table.freeze({
		AbilityId = id,
		Character = stage.User,
		VFX = stage.ClientScope,
		GetAim = function(): AbilityType.Aim
			return Aim.get(stage.User)
		end,
		Raise = function(name: string, payload: unknown, aim: AbilityType.Aim?)
			clientMachine:Raise(name, payload, aim)
		end,
	})
	local serverSetup: Context.ServerSetup = table.freeze({
		AbilityId = id,
		Character = stage.User,
		VFX = stage.ServerScope,
		Raise = function(name: string, payload: unknown, aim: AbilityType.Aim?)
			serverMachine:Raise(name, payload, aim)
		end,
	})
	serverMachine = Machine.new(server, {
		Realm = "Server",
		Store = serverStore,
		NewContext = function(stimulus: Stimulus?, memory: Memory, record: Memory)
			return Context.newServer(serverSetup, stimulus, memory, record)
		end,
		OnFired = function(binding: EventBinding, stimulus: Stimulus)
			if clientMachine then
				clientMachine:Fire(binding.Name, stimulus.Payload, nil)
			end
		end,
		OnRefused = function(binding: EventBinding)
			if clientMachine then
				clientMachine:Refuse(binding.Name, serverMachine.StateId)
			end
		end,
	})
	clientMachine = Machine.new(client, {
		Realm = "Client",
		Store = clientStore,
		NewContext = function(stimulus: Stimulus?, memory: Memory, record: Memory)
			return Context.newClient(clientSetup, stimulus, memory, record)
		end,
		OnFired = function(binding: EventBinding, stimulus: Stimulus)
			serverMachine:Fire(binding.Name, stimulus.Payload, stimulus.Aim or Aim.get(stage.User))
		end,
	})
	return {
		Client = clientMachine,
		Server = serverMachine,
		ClientStore = clientStore,
		ServerStore = serverStore,
		Destroy = function()
			clientMachine:Destroy()
			serverMachine:Destroy()
			clientStore:Destroy()
			serverStore:Destroy()
		end,
	}
end

-- the server hears of a condition first, like it would from a client that reports before it acts
local function setCondition(rig: Rig, stage: Stage, condition: Condition, isActive: boolean)
	local aim = Aim.get(stage.User)
	rig.ServerStore:Set(condition.Key, isActive, aim)
	rig.ClientStore:Set(condition.Key, isActive, aim)
end

local function setState(rig: Rig, stateId: string)
	rig.Server:SetStateId(stateId)
	rig.Client:SetStateId(stateId)
end

-- what a story can flip by hand: nothing the machines work out themselves
local function getIfSettable(condition: Condition): boolean
	return condition.Type ~= "Current" and condition.Type ~= "Elapsed" and condition.Type ~= "AbilityState"
end

local function getRequirements(binding: Binding): { Requirement }
	if binding.Kind == "State" then
		return binding.Trigger.Requirements
	end
	return if binding.Trigger then binding.Trigger.Requirements else {}
end

-- gets the machines to where the binding is live: in one of its states with everything it requires in place
local function prepare(rig: Rig, stage: Stage, binding: Binding)
	local stateIds: { string } = (binding :: any).StateIds
	if not table.find(stateIds, rig.Client.StateId) or not table.find(stateIds, rig.Server.StateId) then
		setState(rig, stateIds[1])
	end
	for _, requirement in getRequirements(binding) do
		if getIfSettable(requirement.Condition) then
			setCondition(rig, stage, requirement.Condition, requirement.IsActive)
		end
	end
end

local function setOff(rig: Rig, stage: Stage, binding: EventBinding, options: Options)
	prepare(rig, stage, binding)
	local trigger = binding.Trigger
	if not trigger then
		local payload = if options.GetPayload then options.GetPayload(stage) else nil
		local machine = if binding.Authority == "Server" then rig.Server else rig.Client
		machine:Raise(binding.Name, payload, Aim.get(stage.User))
		return
	end
	local condition = trigger.Condition
	if not getIfSettable(condition) then
		-- one that waits on the state itself is set off by walking into the state again
		local layout = rig.Client.Definition.Layout
		for _, other: Binding in layout.Bindings do
			local stateIds: { string } = (other :: any).StateIds
			if stateIds[1] ~= binding.StateIds[1] then
				setState(rig, stateIds[1])
				break
			end
		end
		setState(rig, binding.StateIds[1])
		return
	end
	setCondition(rig, stage, condition, not trigger.IsStarted)
	setCondition(rig, stage, condition, trigger.IsStarted)
	-- a press is let go of again, so the next one counts
	task.delay(PULSE_DURATION, function()
		if rig.Client.IsAlive and condition.Type == "Input" then
			setCondition(rig, stage, condition, not trigger.IsStarted)
		end
	end)
end

local function getReadout(rig: Rig, stage: Stage): { string }
	return {
		`client: {rig.Client.StateId}   server: {rig.Server.StateId}`,
		`user energy: {AttributeDefinition.get(stage.User, AttributeDefinition.Energy)}`
			.. `   target health: {AttributeDefinition.get(stage.Target, AttributeDefinition.Health)}`,
		`pvp: {ModeDefinition.getIfPVPEnabled()}   energy: {ModeDefinition.getIfEnergyEnabled()}`,
	}
end
-- Class
local Module = {}

-- the story of one binding of an ability: both halves run on a dummy against another one, wired to each other, so
-- everything the binding sets off on either side can be watched + tuned in the place. the button sets the binding
-- off, the ones below it flip the conditions the ability hangs on by hand
Module.new = function(
	client: ClientDefinition,
	server: ServerDefinition,
	binding: { Kind: "Event" | "State", Name: string },
	options: Options?
)
	local layout = client.Layout
	local resolvedOptions: Options = options or {}
	local target: Binding = layout.Bindings[binding.Name]
	assert(target, `"{binding.Name}" isn't a binding of "{layout.Id}"`)
	-- every condition of the ability a story can flip, once each
	local conditions: { Condition } = {}
	local keys: { [string]: true } = {}
	for _, other: Binding in layout.Bindings do
		local requirements = table.clone(getRequirements(other))
		if other.Kind == "Event" and other.Trigger then
			table.insert(requirements, { Condition = other.Trigger.Condition, IsActive = true })
		end
		for _, requirement in requirements do
			local condition = requirement.Condition
			if getIfSettable(condition) and not keys[condition.Key] then
				keys[condition.Key] = true
				table.insert(conditions, condition)
			end
		end
	end
	table.sort(conditions, function(a: Condition, b: Condition): boolean
		return a.Key < b.Key
	end)

	return UILabs.CreateReactStory({
		react = React,
		reactRoblox = ReactRoblox,
		controls = {
			Distance = UILabs.Slider(resolvedOptions.Distance or 4, 2, 60, 1),
		},
	}, function(props)
		local stage = VFXStory.useStage(props.controls.Distance)
		local rig, setRig = React.useState(nil :: Rig?)
		local readout, setReadout = React.useState({} :: { string })
		React.useEffect(function()
			if not stage then
				return function() end
			end
			AttributeDefinition.setDefaults(stage.User, "Character")
			AttributeDefinition.setDefaults(stage.Target, "Character")
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

		if not stage or not rig then
			return e(VFXStory.Panel, { Lines = { "setting the stage.." }, Buttons = {} })
		end
		local buttons: { VFXStory.PanelButton } = {}
		if target.Kind == "Event" then
			local eventBinding = target
			table.insert(buttons, {
				Text = `set off "{target.Name}"`,
				OnClick = function()
					setOff(rig, stage, eventBinding, resolvedOptions)
				end,
			})
		else
			local isOn = rig.Client._Cleanups[target] ~= nil
			table.insert(buttons, {
				Text = `{if isOn then "stop" else "start"} "{target.Name}"`,
				IsOn = isOn,
				OnClick = function()
					if isOn then
						local requirement = getRequirements(target)[1]
						if requirement and getIfSettable(requirement.Condition) then
							setCondition(rig, stage, requirement.Condition, not requirement.IsActive)
						else
							setState(rig, layout.InitialStateId)
						end
					else
						prepare(rig, stage, target)
					end
				end,
			})
		end
		for _, condition in conditions do
			local isActive = rig.ClientStore:Get(condition.Key)
			table.insert(buttons, {
				Text = `{condition.Key}: {if isActive then "on" else "off"}`,
				IsOn = isActive,
				OnClick = function()
					setCondition(rig, stage, condition, not isActive)
				end,
			})
		end
		local lines = { `"{target.Name}" of {layout.Id}` }
		table.move(readout, 1, #readout, 2, lines)
		return e(VFXStory.Panel, { Lines = lines, Buttons = buttons })
	end)
end

return Module
