--!strict
-- Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityLibrary = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library")
local Aim = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Aim")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ConditionStore = require("@game/ReplicatedStorage/Shared/Ability/ConditionStore")
local Context = require("@game/ReplicatedStorage/Shared/Ability/Context")
local Machine = require("@game/ReplicatedStorage/Shared/Ability/Machine")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local VFXService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/VFX")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ConditionStore = ConditionStore.ConditionStore
type Machine = Machine.Machine
type Aim = AbilityType.Aim
type Grant = AbilityType.Grant
type Update = AbilityType.Update
type Condition = AbilityType.Condition
type Requirement = AbilityType.Requirement
type Binding = AbilityType.Binding
type EventBinding = AbilityType.EventBinding
type Stimulus = AbilityType.Stimulus
type Memory = AbilityType.Memory
type ClientDefinition = AbilityType.ClientDefinition
-- the client halves of the abilities of the avatar the local player is in, gone with it
type Loadout = {
	Character: Model,
	Store: ConditionStore,
	Machines: { [string]: Machine },
	-- the conditions that are this client's to work out + tell the server of, by their key
	Inputs: { [string]: Condition },
	HumanoidStates: { [string]: Condition },
	-- the abilities whose tool is in the hand
	EquippedIds: { [string]: true },
	-- the tools that left the hand a moment ago + aren't counted as put away yet, by their ability: what took their
	-- place may be about to give way to them. only ever in a game that keeps the hand
	LeavingTools: { [string]: Tool },
	-- one of its tools is out or one of its machines isn't where it rests
	IsEngaged: boolean,
	-- what keeps the avatar where it stands for as long as the server has it frozen
	FrozenHold: VFXType.Handle?,
	Connections: { RBXScriptConnection },
}
type AbilityServiceImpl = {
	__index: AbilityServiceImpl,
	-- if an ability of the local player has their hand: one of its tools is out, or one of its machines isn't where
	-- it rests
	GetIfEngaged: (self: AbilityService) -> boolean,
	-- has an engaged ability keep the hand from then on, the way the server does it + before it hears of anything:
	-- a tool that isn't a power's goes straight back as it's picked + the tool it took the place of comes back out,
	-- the ability never hears that it left. without, whatever is picked is in the hand
	KeepHand: (self: AbilityService) -> (),
}
export type AbilityService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- an ability of the local player took their hand or let go of it
		EngagedChanged: Signal.Signal<boolean>,
		_IsHandKept: boolean,
		_Loadout: Loadout?,
		-- what the server last gave the character, kept for an avatar that shows up after the news of it did
		_Grants: { Grant },
		-- how many of each are held down right now, a second finger doesn't let go of the first
		_HeldCounts: { [EnumItem]: number },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: AbilityServiceImpl
))
-- Constants
-- seconds an avatar gets to finish arriving
local AVATAR_TIMEOUT = 10
-- Variables
-- References
-- Private Functions
local function unload(self: AbilityService)
	local loadout = self._Loadout
	if not loadout then
		return
	end
	self._Loadout = nil
	for _, v in loadout.Connections do
		v:Disconnect()
	end
	for _, machine in loadout.Machines do
		machine:Destroy()
	end
	if loadout.FrozenHold then
		loadout.FrozenHold.Stop()
		loadout.FrozenHold = nil
	end
	loadout.Store:Destroy()
	if loadout.IsEngaged then
		loadout.IsEngaged = false
		self.EngagedChanged:Fire(false)
	end
end

local settleHand: (self: AbilityService, loadout: Loadout) -> ()

-- an ability has the hand while one of its tools is out or one of its machines isn't where it rests
local function refreshEngaged(self: AbilityService, loadout: Loadout)
	local isEngaged = next(loadout.EquippedIds) ~= nil
	if not isEngaged then
		for _, machine in loadout.Machines do
			if machine.StateId ~= machine.Definition.Layout.InitialStateId then
				isEngaged = true
				break
			end
		end
	end
	if isEngaged == loadout.IsEngaged or self._Loadout ~= loadout then
		return
	end
	loadout.IsEngaged = isEngaged
	self.EngagedChanged:Fire(isEngaged)
	-- whatever else is in the hand it took goes back
	if isEngaged and self._IsHandKept then
		task.defer(settleHand, self, loadout)
	end
end

-- the tool of an ability is in the hand, or it's put away for good
local function setEquipped(self: AbilityService, loadout: Loadout, id: string, isEquipped: boolean)
	if isEquipped then
		loadout.EquippedIds[id] = true
	else
		loadout.EquippedIds[id] = nil
	end
	loadout.Store:Set(AbilityCondition.equipped(id).Key, isEquipped, Aim.get(loadout.Character))
	refreshEngaged(self, loadout)
end

-- every tool that's on its way out of the hand is put away for good: nothing is about to give way to it
local function flushHand(self: AbilityService, loadout: Loadout)
	for id in loadout.LeavingTools do
		loadout.LeavingTools[id] = nil
		setEquipped(self, loadout, id, false)
	end
end

-- puts the hand right once whatever changed in it is in, the way the server does. an engaged ability keeps it: a tool
-- that isn't a power's goes back where it came from + the tool it took the place of comes back out, without its
-- ability ever hearing that it left. a tool that left the hand to nothing is put away for good
function settleHand(self: AbilityService, loadout: Loadout)
	if not self.IsInitialized or self._Loadout ~= loadout then
		return
	end
	local character = loadout.Character
	local backpack = Players.LocalPlayer:FindFirstChildOfClass("Backpack")
	local isTakenBack = false
	if backpack and loadout.IsEngaged then
		for _, child in character:GetChildren() do
			if child:IsA("Tool") and child:GetAttribute(PowerDefinition.TOOL_ID_ATTRIBUTE) == nil then
				child.Parent = backpack
				isTakenBack = true
			end
		end
	end
	for id, tool in loadout.LeavingTools do
		loadout.LeavingTools[id] = nil
		if isTakenBack and tool.Parent == backpack then
			tool.Parent = character
		end
		-- one that's out again by now never left as far as its ability goes
		if tool.Parent ~= character then
			setEquipped(self, loadout, id, false)
		end
	end
end

local function report(key: string, isActive: boolean, aim: Aim)
	if NetworkService.IsInitialized then
		NetworkService:Fire(
			RemoteDefinition.AbilityReported,
			table.freeze({
				Type = "Condition" :: "Condition",
				Key = key,
				IsActive = isActive,
				Aim = aim,
			})
		)
	end
end

local function addConditions(definition: ClientDefinition, loadout: Loadout)
	for _, binding: Binding in definition.Layout.Bindings do
		local requirements: { Requirement } = {}
		if binding.Kind == "State" then
			requirements = binding.Trigger.Requirements
		elseif binding.Trigger then
			requirements = table.clone(binding.Trigger.Requirements)
			table.insert(requirements, { Condition = binding.Trigger.Condition, IsActive = true })
		end
		for _, requirement in requirements do
			local condition = requirement.Condition
			if condition.Type == "Input" then
				loadout.Inputs[condition.Key] = condition
			elseif condition.Type == "HumanoidState" then
				loadout.HumanoidStates[condition.Key] = condition
			end
		end
	end
end

local function getIfHeld(self: AbilityService, condition: Condition): boolean
	if condition.Type ~= "Input" then
		return false
	end
	for _, userInputType in condition.UserInputTypes do
		if (self._HeldCounts[userInputType] or 0) > 0 then
			return true
		end
	end
	for _, keyCode in condition.KeyCodes do
		if (self._HeldCounts[keyCode] or 0) > 0 then
			return true
		end
	end
	return false
end

-- works out every input condition anew, whatever changed goes to the machines + to the server
local function refreshInputs(self: AbilityService)
	local loadout = self._Loadout
	if not loadout then
		return
	end
	local character = loadout.Character
	-- somebody who's dead or sat in a menu still lets go of what they held, they don't start anything new
	local isBusy = AttributeDefinition.get(character, AttributeDefinition.IsDead)
		or AttributeDefinition.get(character, AttributeDefinition.IsInMenu)
	for key, condition in loadout.Inputs do
		local isHeld = getIfHeld(self, condition)
		if isHeld ~= loadout.Store:Get(key) and not (isHeld and isBusy) then
			local aim = Aim.get(character)
			-- the server hears of it first: what the machines make of it here may be on its way to it right after
			report(key, isHeld, aim)
			loadout.Store:Set(key, isHeld, aim)
		end
	end
end

local function onInput(self: AbilityService, input: InputObject, isBegan: boolean)
	local items: { EnumItem } = { input.UserInputType }
	-- an input that isn't a key or a button of a gamepad comes with the key code that stands for none
	if input.KeyCode.Value ~= 0 then
		table.insert(items, input.KeyCode)
	end
	for _, item in items do
		self._HeldCounts[item] = math.max(0, (self._HeldCounts[item] or 0) + (if isBegan then 1 else -1))
	end
	refreshInputs(self)
end

local function setHumanoidState(loadout: Loadout, humanoidStateType: Enum.HumanoidStateType, isActive: boolean)
	local key = AbilityCondition.humanoidState(humanoidStateType).Key
	if loadout.HumanoidStates[key] and loadout.Store:Get(key) ~= isActive then
		local aim = Aim.get(loadout.Character)
		report(key, isActive, aim)
		loadout.Store:Set(key, isActive, aim)
	end
end

local function getAbilityId(inst: Instance): string?
	local id = if inst:IsA("Tool") then inst:GetAttribute(PowerDefinition.TOOL_ID_ATTRIBUTE) else nil
	return if type(id) == "string" then id else nil
end

local function newMachine(character: Model, grant: Grant, definition: ClientDefinition, store: ConditionStore): Machine
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	local id = definition.Layout.Id
	local machine: Machine
	local setup: Context.ClientSetup = table.freeze({
		AbilityId = id,
		Character = character,
		Player = Players.LocalPlayer,
		Color = grant.Color,
		SecondaryColor = grant.SecondaryColor,
		VFX = VFXService:NewScope(character),
		GetAim = function(): Aim
			return Aim.get(character)
		end,
		Raise = function(name: string, payload: unknown, aim: Aim?)
			machine:Raise(name, payload, aim)
		end,
	})
	machine = Machine.new(definition, {
		Realm = "Client",
		Store = store,
		NewContext = function(stimulus: Stimulus?, memory: Memory, record: Memory)
			return Context.newClient(setup, stimulus, memory, record)
		end,
		-- the server half can't work these out for itself, it's told + gets to check
		OnFired = function(binding: EventBinding, stimulus: Stimulus)
			if NetworkService.IsInitialized then
				NetworkService:Fire(
					RemoteDefinition.AbilityReported,
					table.freeze({
						Type = "Binding" :: "Binding",
						AbilityId = id,
						Name = binding.Name,
						Payload = stimulus.Payload,
						Aim = stimulus.Aim or Aim.get(character),
					})
				)
			end
		end,
	})
	return machine
end

local function load(self: AbilityService, grants: { Grant })
	unload(self)
	local character = Players.LocalPlayer.Character
	local humanoid = character and character:FindFirstChildWhichIsA("Humanoid")
	if not character or not humanoid then
		return
	end
	local store = ConditionStore.new()
	local loadout: Loadout = {
		Character = character,
		Store = store,
		Machines = {},
		Inputs = {},
		HumanoidStates = {},
		EquippedIds = {},
		LeavingTools = {},
		IsEngaged = false,
		Connections = {},
	}
	self._Loadout = loadout
	for _, grant in grants do
		local definition = AbilityLibrary.get(grant.Id)
		if definition then
			addConditions(definition, loadout)
			local machine = newMachine(character, grant, definition, store)
			loadout.Machines[grant.Id] = machine
			-- gone with the machine
			machine.StateChanged:Connect(function()
				refreshEngaged(self, loadout)
			end)
		end
	end
	-- a machine can be off where it rests by the time it's made
	refreshEngaged(self, loadout)

	-- a tool is equipped by being moved into the avatar
	local function onChild(inst: Instance, isEquipped: boolean)
		local abilityId = getAbilityId(inst)
		if not abilityId then
			-- a tool that isn't a power's in a hand an ability has: the engine is still putting it there, it's sent
			-- back once it's in
			if isEquipped and self._IsHandKept and loadout.IsEngaged and inst:IsA("Tool") then
				task.defer(settleHand, self, loadout)
			end
		elseif isEquipped then
			-- back before it counted as put away: its ability never hears that it left
			if loadout.LeavingTools[abilityId] then
				loadout.LeavingTools[abilityId] = nil
				return
			end
			-- a switch between two powers: the one that left is put away first, the way the hotbar did it
			flushHand(self, loadout)
			setEquipped(self, loadout, abilityId, true)
		elseif self._IsHandKept and loadout.EquippedIds[abilityId] then
			-- the hotbar takes one tool out of the hand + puts the next in in one go: whatever took its place is
			-- there by the time this step is over, + may be about to give way to it
			loadout.LeavingTools[abilityId] = inst :: Tool
			task.defer(settleHand, self, loadout)
		else
			setEquipped(self, loadout, abilityId, false)
		end
	end
	table.insert(
		loadout.Connections,
		character.ChildAdded:Connect(function(child: Instance)
			onChild(child, true)
		end)
	)
	table.insert(
		loadout.Connections,
		character.ChildRemoved:Connect(function(child: Instance)
			onChild(child, false)
		end)
	)
	for _, child in character:GetChildren() do
		onChild(child, true)
	end

	table.insert(
		loadout.Connections,
		humanoid.StateChanged:Connect(function(old: Enum.HumanoidStateType, new: Enum.HumanoidStateType)
			setHumanoidState(loadout, old, false)
			setHumanoidState(loadout, new, true)
		end)
	)
	setHumanoidState(loadout, humanoid:GetState(), true)
	table.insert(
		loadout.Connections,
		character.AncestryChanged:Connect(function()
			if not character:IsDescendantOf(game) and self.IsInitialized and self._Loadout == loadout then
				unload(self)
			end
		end)
	)
	-- the server says when the avatar is frozen, holding it is up to the client that walks it: a pace the server
	-- wrote would be in the way of every move that sets one
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	local scope = VFXService:NewScope(character)
	local function refreshFrozen()
		local isFrozen = AttributeDefinition.get(character, AttributeDefinition.IsFrozen)
		local hold = loadout.FrozenHold
		if isFrozen and not hold then
			loadout.FrozenHold = scope.start(ClientVFXDefinition.Root, {})
		elseif not isFrozen and hold then
			loadout.FrozenHold = nil
			hold.Stop()
		end
	end
	table.insert(
		loadout.Connections,
		character:GetAttributeChangedSignal(AttributeDefinition.IsFrozen.Name):Connect(refreshFrozen)
	)
	refreshFrozen()
	refreshInputs(self)
end

local function onUpdated(self: AbilityService, update: Update)
	if update.Type == "Granted" then
		self._Grants = update.Grants
		load(self, update.Grants)
		return
	end
	local loadout = self._Loadout
	if not loadout then
		return
	end
	if update.Type == "Binding" then
		local machine = loadout.Machines[update.AbilityId]
		if machine then
			machine:Fire(update.Name, update.Payload, nil)
		end
	elseif update.Type == "Refused" then
		local machine = loadout.Machines[update.AbilityId]
		if machine then
			machine:Refuse(update.Name, update.StateId)
		end
	else
		loadout.Store:Set(AbilityCondition.custom(update.Name).Key, update.IsActive)
	end
end
-- Class
local AbilityService = {} :: AbilityServiceImpl
AbilityService.__index = AbilityService

function AbilityService:GetIfEngaged(): boolean
	assert(self.IsInitialized, `the ability service isn't initialized`)
	local loadout = self._Loadout
	return loadout ~= nil and loadout.IsEngaged
end

-- said once as the game starts, before the player has abilities
function AbilityService:KeepHand()
	assert(self.IsInitialized, `the ability service isn't initialized`)
	self._IsHandKept = true
end

return ServiceLocker(function(): AbilityService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		EngagedChanged = Signal.new() :: Signal.Signal<boolean>,
		_IsHandKept = false,
		_Loadout = nil :: Loadout?,
		_Grants = {},
		_HeldCounts = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, AbilityService)

	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.AbilityUpdated, function(update: Update)
			onUpdated(self, update)
		end)
	)
	-- the grant for a new avatar can get here before the avatar does, the halves are built again once it's there
	table.insert(
		self._Connections,
		Players.LocalPlayer.CharacterAdded:Connect(function(character: Model)
			character:WaitForChild("Humanoid", AVATAR_TIMEOUT)
			if self.IsInitialized and Players.LocalPlayer.Character == character then
				load(self, self._Grants)
			end
		end)
	)
	table.insert(
		self._Connections,
		UserInputService.InputBegan:Connect(function(input: InputObject, isProcessed: boolean)
			-- a click on a button of the interface isn't meant for the world
			if not isProcessed then
				onInput(self, input, true)
			end
		end)
	)
	table.insert(
		self._Connections,
		UserInputService.InputEnded:Connect(function(input: InputObject)
			onInput(self, input, false)
		end)
	)

	return self
end, function(self: AbilityService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	unload(self)
	self.EngagedChanged:Destroy()
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
