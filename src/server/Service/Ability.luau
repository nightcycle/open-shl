--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityLibrary = require("@game/ServerScriptService/Server/Ability/Library")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local ConditionStore = require("@game/ReplicatedStorage/Shared/Ability/ConditionStore")
local Context = require("@game/ReplicatedStorage/Shared/Ability/Context")
local Machine = require("@game/ReplicatedStorage/Shared/Ability/Machine")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local VFXService = require("@game/ServerScriptService/Server/Service/VFX")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ConditionStore = ConditionStore.ConditionStore
type Machine = Machine.Machine
type Aim = AbilityType.Aim
type Grant = AbilityType.Grant
type Report = AbilityType.Report
type Stimulus = AbilityType.Stimulus
type Memory = AbilityType.Memory
type Binding = AbilityType.Binding
type EventBinding = AbilityType.EventBinding
type Requirement = AbilityType.Requirement
type ServerDefinition = AbilityType.ServerDefinition
-- the abilities of one avatar, gone with it
type Loadout = {
	Character: Model,
	Store: ConditionStore,
	Machines: { [string]: Machine },
	-- the conditions the client of the player has a say in, anything else it reports is dropped
	ReportedKeys: { [string]: true },
	Energy: number, -- as of the last time it was looked at
	Connections: { RBXScriptConnection },
}
type AbilityServiceImpl = {
	__index: AbilityServiceImpl,
	Grant: (self: AbilityService, player: Player, character: Model, grants: { Grant }) -> (),
	SetCustom: (self: AbilityService, player: Player, name: string, isActive: boolean) -> (),
}
export type AbilityService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Loadouts: { [Player]: Loadout },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: AbilityServiceImpl
))
-- Constants
local ENERGY_INTERVAL = 1
-- what a character gets back with every interval they didn't spend any in
local ENERGY_GAIN = 12
-- seconds the server is ahead of what a binding waits for
local LENIENCY = 0.15
-- Variables
-- References
-- Private Functions
local function newTool(definition: PowerDefinition.PowerDefinition): Tool
	local icon = definition.Icon
	local tool = Instance.new("Tool")
	tool.Name = definition.Name
	tool.ToolTip = definition.Name
	tool.TextureId = if icon.Type == "Decal" then icon.Url else icon.SheetUrl
	tool.RequiresHandle = false
	tool.CanBeDropped = false
	tool:SetAttribute(PowerDefinition.TOOL_ID_ATTRIBUTE, definition.Id)
	return tool
end

local function removeTools(player: Player, character: Model)
	local backpack = player:FindFirstChildOfClass("Backpack")
	for _, holder: Instance in { backpack or character, character } do
		for _, v in holder:GetChildren() do
			if v:IsA("Tool") and v:GetAttribute(PowerDefinition.TOOL_ID_ATTRIBUTE) ~= nil then
				v:Destroy()
			end
		end
	end
end

local function unload(self: AbilityService, player: Player)
	local loadout = self._Loadouts[player]
	if not loadout then
		return
	end
	self._Loadouts[player] = nil
	for _, v in loadout.Connections do
		v:Disconnect()
	end
	for _, machine in loadout.Machines do
		machine:Destroy()
	end
	loadout.Store:Destroy()
	if VFXService.IsInitialized then
		VFXService:SetRelays(player, nil)
	end
end

-- an input or what the humanoid is doing is the client's to tell
local function addReportedKeys(definition: ServerDefinition, keys: { [string]: true })
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
			if condition.Type == "Input" or condition.Type == "HumanoidState" then
				keys[condition.Key] = true
			end
		end
	end
end

local function newMachine(
	player: Player,
	character: Model,
	grant: Grant,
	definition: ServerDefinition,
	store: ConditionStore
): Machine
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	local id = definition.Layout.Id
	local machine: Machine
	local setup: Context.ServerSetup = table.freeze({
		AbilityId = id,
		Character = character,
		Player = player,
		Color = grant.Color,
		SecondaryColor = grant.SecondaryColor,
		VFX = VFXService:NewScope(player, character),
		Raise = function(name: string, payload: unknown, aim: Aim?)
			machine:Raise(name, payload, aim)
		end,
	})
	machine = Machine.new(definition, {
		Realm = "Server",
		Store = store,
		Leniency = LENIENCY,
		NewContext = function(stimulus: Stimulus?, memory: Memory, record: Memory)
			return Context.newServer(setup, stimulus, memory, record)
		end,
		-- the client half can't work these out for itself, it follows as it's told
		OnFired = function(binding: EventBinding, stimulus: Stimulus)
			if NetworkService.IsInitialized then
				NetworkService:Fire(
					RemoteDefinition.AbilityUpdated,
					player,
					table.freeze({
						Type = "Binding" :: "Binding",
						AbilityId = id,
						Name = binding.Name,
						Payload = stimulus.Payload,
					})
				)
			end
		end,
		-- the client went ahead with it, it has to hear that it stands alone
		OnRefused = function(binding: EventBinding)
			if NetworkService.IsInitialized then
				NetworkService:Fire(
					RemoteDefinition.AbilityUpdated,
					player,
					table.freeze({
						Type = "Refused" :: "Refused",
						AbilityId = id,
						Name = binding.Name,
						StateId = machine.StateId,
					})
				)
			end
		end,
	})
	return machine
end

local function onReported(self: AbilityService, player: Player, report: Report)
	local loadout = self._Loadouts[player]
	if not loadout or loadout.Character ~= player.Character then
		return
	end
	local character = loadout.Character
	-- somebody who's dead or sat in a menu still lets go of what they held, they don't start anything new
	local isBusy = AttributeDefinition.get(character, AttributeDefinition.IsDead)
		or AttributeDefinition.get(character, AttributeDefinition.IsInMenu)
	if report.Type == "Condition" then
		if loadout.ReportedKeys[report.Key] and not (report.IsActive and isBusy) then
			loadout.Store:Set(report.Key, report.IsActive, report.Aim)
		end
		return
	end
	-- the machine drops what isn't the client's to say or doesn't carry what the binding takes, the server half of
	-- the binding checks the rest
	local machine = loadout.Machines[report.AbilityId]
	if not machine then
		return
	end
	-- a binding that leads back to where the ability rests lets go of something, it gets through like a button
	-- that's let go of does
	local layout = machine.Definition.Layout
	local binding: Binding? = layout.Bindings[report.Name]
	local isLettingGo = binding ~= nil and binding.Kind == "Event" and binding.To == layout.InitialStateId
	if not isBusy or isLettingGo then
		machine:Fire(report.Name, report.Payload, report.Aim)
	end
end

-- a character that didn't spend any energy since the last look gets some back
local function gainEnergy(self: AbilityService)
	for _, loadout in self._Loadouts do
		local character = loadout.Character
		local energy = AttributeDefinition.get(character, AttributeDefinition.Energy)
		if energy >= loadout.Energy and energy < AttributeDefinition.MAX_ENERGY then
			energy = math.min(AttributeDefinition.MAX_ENERGY, energy + ENERGY_GAIN)
			AttributeDefinition.set(character, AttributeDefinition.Energy, energy)
		end
		loadout.Energy = energy
	end
end

-- a character that's hurt + still up gets some health back
local function gainHealth(self: AbilityService, amount: number)
	for _, loadout in self._Loadouts do
		local character = loadout.Character
		local health = AttributeDefinition.get(character, AttributeDefinition.Health)
		if
			health < AttributeDefinition.MAX_HEALTH
			and not AttributeDefinition.get(character, AttributeDefinition.IsDead)
		then
			health = math.min(AttributeDefinition.MAX_HEALTH, health + amount)
			AttributeDefinition.set(character, AttributeDefinition.Health, health)
		end
	end
end
-- Class
local AbilityService = {} :: AbilityServiceImpl
AbilityService.__index = AbilityService

-- gives an avatar its abilities in place of whatever it had: a machine for each that's built, a tool for each that
-- comes with one. the order of the grants is the order of the hotbar
function AbilityService:Grant(player: Player, character: Model, grants: { Grant })
	assert(self.IsInitialized, `the ability service isn't initialized`)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	unload(self, player)
	removeTools(player, character)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not backpack then
		warn(`{player.Name} has no backpack to hold their abilities`)
		return
	end
	local store = ConditionStore.new()
	local loadout: Loadout = {
		Character = character,
		Store = store,
		Machines = {},
		ReportedKeys = {},
		Energy = AttributeDefinition.get(character, AttributeDefinition.Energy),
		Connections = {},
	}
	self._Loadouts[player] = loadout
	-- the client builds its halves off this, it has to be there before anything the machines have to say
	NetworkService:Fire(
		RemoteDefinition.AbilityUpdated,
		player,
		table.freeze({
			Type = "Granted" :: "Granted",
			Grants = grants,
		})
	)
	local relays: { [string]: VFXType.Reach } = {}
	for _, grant in grants do
		local powerRes = PowerDefinition.get(grant.Id)
		if powerRes.IsErr then
			warn(`ability err: {powerRes.Value}`)
			continue
		end
		local definition = AbilityLibrary.get(grant.Id)
		-- one that isn't built yet still takes up its slot of the hotbar
		if not definition or definition.Layout.HasTool then
			local tool = newTool(powerRes.Value)
			local key = AbilityCondition.equipped(grant.Id).Key
			table.insert(
				loadout.Connections,
				tool.Equipped:Connect(function()
					store:Set(key, true)
				end)
			)
			table.insert(
				loadout.Connections,
				tool.Unequipped:Connect(function()
					store:Set(key, false)
				end)
			)
			tool.Parent = backpack
		end
		if definition then
			addReportedKeys(definition, loadout.ReportedKeys)
			for name, reach in definition.Relays do
				relays[name] = reach
			end
			loadout.Machines[grant.Id] = newMachine(player, character, grant, definition, store)
		end
	end
	VFXService:SetRelays(player, relays)
	table.insert(
		loadout.Connections,
		character.AncestryChanged:Connect(function()
			if not character:IsDescendantOf(game) and self.IsInitialized and self._Loadouts[player] == loadout then
				unload(self, player)
			end
		end)
	)
end

-- a per player condition some other system of the game owns, the bindings that hang on it follow on both sides
function AbilityService:SetCustom(player: Player, name: string, isActive: boolean)
	assert(self.IsInitialized, `the ability service isn't initialized`)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local loadout = self._Loadouts[player]
	if not loadout then
		return
	end
	loadout.Store:Set(AbilityCondition.custom(name).Key, isActive)
	NetworkService:Fire(
		RemoteDefinition.AbilityUpdated,
		player,
		table.freeze({
			Type = "Custom" :: "Custom",
			Name = name,
			IsActive = isActive,
		})
	)
end

return ServiceLocker(function(): AbilityService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Loadouts = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, AbilityService)

	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.AbilityReported, function(player: Player, report: Report)
			onReported(self, player, report)
		end)
	)
	table.insert(
		self._Connections,
		Players.PlayerRemoving:Connect(function(player: Player)
			unload(self, player)
		end)
	)
	if ModeDefinition.getIfEnergyEnabled() then
		local energyThread = task.spawn(function()
			while true do
				task.wait(ENERGY_INTERVAL)
				gainEnergy(self)
			end
		end)
		table.insert(self._CleanUpCallbacks, function()
			task.cancel(energyThread)
		end)
	end
	-- not every game has health come back by itself
	local regeneration = CombatDefinition.REGENERATION
	if regeneration then
		local healthThread = task.spawn(function()
			while true do
				task.wait(regeneration.Interval)
				gainHealth(self, regeneration.Amount)
			end
		end)
		table.insert(self._CleanUpCallbacks, function()
			task.cancel(healthThread)
		end)
	end

	return self
end, function(self: AbilityService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for player in self._Loadouts do
		unload(self, player)
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
