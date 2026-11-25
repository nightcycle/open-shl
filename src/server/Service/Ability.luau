--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
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
local ToolUtil = require("@game/ServerScriptService/Server/Util/Tool")
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
	-- the abilities whose tool is in the hand
	EquippedIds: { [string]: true },
	-- the tools that left the hand a moment ago + aren't counted as put away yet, by their ability: what took their
	-- place may be about to give way to them. only ever in a game that keeps the hand
	LeavingTools: { [string]: Tool },
	-- one of its tools is out or one of its machines isn't where it rests
	IsEngaged: boolean,
	Connections: { RBXScriptConnection },
}
type AbilityServiceImpl = {
	__index: AbilityServiceImpl,
	Grant: (self: AbilityService, player: Player, character: Model, grants: { Grant }) -> (),
	SetCustom: (self: AbilityService, player: Player, name: string, isActive: boolean) -> (),
	-- if an ability of the player has their hand: one of its tools is out, or one of its machines isn't where it rests
	GetIfEngaged: (self: AbilityService, player: Player) -> boolean,
	-- has an engaged ability keep the hand of its player from then on, for a game that puts tools of its own in the
	-- hotbar: one of those that's picked goes straight back + the tool it took the place of comes back out, the
	-- ability never hears that it left. without, whatever is picked is in the hand
	KeepHand: (self: AbilityService) -> (),
}
export type AbilityService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- an ability of the player took their hand or let go of it. whatever else they hold gives way for as long as
		-- it has it
		EngagedChanged: Signal.Signal<Player, boolean>,
		-- the abilities of an avatar are about to be handed out anew: everything it wears is about to change
		Granted: Signal.Signal<Player, Model>,
		_IsHandKept: boolean,
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
-- seconds the tool of an ability that left the hand gets before it counts as put away: whatever was picked in its
-- place gets here with it or right behind it. less than the server is ahead by, so a tool that's really put away is
-- never late for what its ability waits for
local HAND_GRACE = 0.05
-- Variables
-- References
-- Private Functions
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
	if loadout.IsEngaged then
		loadout.IsEngaged = false
		self.EngagedChanged:Fire(player, false)
	end
end

local settleHand: (self: AbilityService, player: Player, loadout: Loadout) -> ()

-- an ability has the hand of its player while one of its tools is out or one of its machines isn't where it rests
local function refreshEngaged(self: AbilityService, player: Player, loadout: Loadout)
	local isEngaged = next(loadout.EquippedIds) ~= nil
	if not isEngaged then
		for _, machine in loadout.Machines do
			if machine.StateId ~= machine.Definition.Layout.InitialStateId then
				isEngaged = true
				break
			end
		end
	end
	if isEngaged == loadout.IsEngaged or self._Loadouts[player] ~= loadout then
		return
	end
	loadout.IsEngaged = isEngaged
	self.EngagedChanged:Fire(player, isEngaged)
	-- whatever else is in the hand it took goes back
	if isEngaged and self._IsHandKept then
		task.defer(settleHand, self, player, loadout)
	end
end

-- the tool of an ability is in the hand, or it's put away for good
local function setEquipped(self: AbilityService, player: Player, loadout: Loadout, id: string, isEquipped: boolean)
	if isEquipped then
		loadout.EquippedIds[id] = true
	else
		loadout.EquippedIds[id] = nil
	end
	loadout.Store:Set(AbilityCondition.equipped(id).Key, isEquipped)
	refreshEngaged(self, player, loadout)
end

-- every tool that's on its way out of the hand is put away for good: nothing is about to give way to it
local function flushHand(self: AbilityService, player: Player, loadout: Loadout)
	for id in loadout.LeavingTools do
		loadout.LeavingTools[id] = nil
		setEquipped(self, player, loadout, id, false)
	end
end

-- puts the hand of a player right once whatever changed in it is in. an engaged ability keeps it: a tool that isn't a
-- power's goes back where it came from + the tool it took the place of comes back out, without its ability ever
-- hearing that it left. a tool that left the hand to nothing is put away for good
function settleHand(self: AbilityService, player: Player, loadout: Loadout)
	if not self.IsInitialized or self._Loadouts[player] ~= loadout then
		return
	end
	local character = loadout.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
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
		-- one that's out again by now never left as far as its ability goes: whoever picked the other tool may have
		-- put the hand right themselves
		if tool.Parent ~= character then
			setEquipped(self, player, loadout, id, false)
		end
	end
end

-- has a loadout send back whatever else comes into the hand of its avatar while one of its abilities is engaged, for
-- as long as it lasts. only ever in a game that keeps the hand, once for every loadout
local function watchHand(self: AbilityService, player: Player, loadout: Loadout)
	table.insert(
		loadout.Connections,
		loadout.Character.ChildAdded:Connect(function(child: Instance)
			-- the engine is still putting it there, it's sent back once it's in
			if
				loadout.IsEngaged
				and child:IsA("Tool")
				and child:GetAttribute(PowerDefinition.TOOL_ID_ATTRIBUTE) == nil
			then
				task.defer(settleHand, self, player, loadout)
			end
		end)
	)
end

local function onEquipped(self: AbilityService, player: Player, loadout: Loadout, id: string)
	-- back before it counted as put away: its ability never hears that it left
	if loadout.LeavingTools[id] then
		loadout.LeavingTools[id] = nil
		return
	end
	-- a switch between two powers: the one that left is put away first, the way the hotbar did it
	flushHand(self, player, loadout)
	setEquipped(self, player, loadout, id, true)
end

local function onUnequipped(self: AbilityService, player: Player, loadout: Loadout, id: string, tool: Tool)
	if not self._IsHandKept or not loadout.EquippedIds[id] then
		setEquipped(self, player, loadout, id, false)
		return
	end
	-- whatever took its place may be about to give way to it
	loadout.LeavingTools[id] = tool
	task.delay(HAND_GRACE, settleHand, self, player, loadout)
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
	-- whatever the client says, it says of a hand its tool already left
	flushHand(self, player, loadout)
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
	self.Granted:Fire(player, character)
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
		EquippedIds = {},
		LeavingTools = {},
		IsEngaged = false,
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
			local power = powerRes.Value
			local tool = ToolUtil.new(power.Name, power.Icon, PowerDefinition.TOOL_ID_ATTRIBUTE, power.Id)
			table.insert(
				loadout.Connections,
				tool.Equipped:Connect(function()
					onEquipped(self, player, loadout, grant.Id)
				end)
			)
			table.insert(
				loadout.Connections,
				tool.Unequipped:Connect(function()
					onUnequipped(self, player, loadout, grant.Id, tool)
				end)
			)
			tool.Parent = backpack
		end
		if definition then
			addReportedKeys(definition, loadout.ReportedKeys)
			for name, reach in definition.Relays do
				relays[name] = reach
			end
			local machine = newMachine(player, character, grant, definition, store)
			loadout.Machines[grant.Id] = machine
			-- gone with the machine
			machine.StateChanged:Connect(function()
				refreshEngaged(self, player, loadout)
			end)
		end
	end
	VFXService:SetRelays(player, relays)
	-- a machine can be off where it rests by the time it's handed over
	refreshEngaged(self, player, loadout)
	if self._IsHandKept then
		watchHand(self, player, loadout)
	end
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

function AbilityService:GetIfEngaged(player: Player): boolean
	assert(self.IsInitialized, `the ability service isn't initialized`)
	local loadout = self._Loadouts[player]
	return loadout ~= nil and loadout.IsEngaged
end

-- said once as the game starts. whoever has their abilities by then is held to it from here on, the same as
-- everybody who gets theirs later
function AbilityService:KeepHand()
	assert(self.IsInitialized, `the ability service isn't initialized`)
	if self._IsHandKept then
		return
	end
	self._IsHandKept = true
	for player, loadout in self._Loadouts do
		watchHand(self, player, loadout)
		-- whatever else got into a hand an ability already had goes back
		if loadout.IsEngaged then
			task.defer(settleHand, self, player, loadout)
		end
	end
end

return ServiceLocker(function(): AbilityService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		EngagedChanged = Signal.new() :: Signal.Signal<Player, boolean>,
		Granted = Signal.new() :: Signal.Signal<Player, Model>,
		_IsHandKept = false,
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
	self.EngagedChanged:Destroy()
	self.Granted:Destroy()
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
