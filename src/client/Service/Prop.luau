--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local AbilityService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Ability")
local Aim = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Aim")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local PropDefinition = require("@game/ReplicatedStorage/Shared/Definition/Prop")
local PropLibrary = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local Runner = require("@game/ReplicatedStorage/Shared/Prop/Runner")
local VFXService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/VFX")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
type Runner = Runner.Runner
type Aim = AbilityType.Aim
type Memory = AbilityType.Memory
type ClientContext = PropType.ClientContext
-- one prop the server handed the local player: its slot of the hotbar + the half this client runs of it
type Entry = {
	Id: string,
	Tool: Tool,
	-- made the first time it's got out, for the avatar whose hand it's in
	Runner: Runner?,
	Character: Model?,
	Connections: { RBXScriptConnection },
}
type PropServiceImpl = {
	__index: PropServiceImpl,
}
export type PropService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Entries: { [Tool]: Entry },
		-- the one this client counts as in the hand
		_HeldTool: Tool?,
		_BackpackConnections: { RBXScriptConnection },
		_CharacterConnections: { RBXScriptConnection },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: PropServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
local function getRunner(entry: Entry, character: Model): Runner
	local current = entry.Runner
	if current and entry.Character == character then
		return current
	end
	if current then
		current:Destroy()
	end
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	local id = entry.Id
	local scope = VFXService:NewScope(character)
	local runner = Runner.new(PropLibrary.get(id), {
		NewContext = function(aim: Aim?, memory: Memory, record: Memory): ClientContext
			return table.freeze({
				PropId = id,
				Character = character,
				Player = Players.LocalPlayer,
				Aim = aim,
				Memory = memory,
				Record = record,
				VFX = scope,
				getAim = function(): Aim
					return Aim.get(character)
				end,
			})
		end,
		-- the server hears of a click first: what it gives is the server's, what shows here is on its way right after
		OnUsed = function(aim: Aim?)
			if NetworkService.IsInitialized then
				NetworkService:Fire(RemoteDefinition.PropReported, table.freeze({ Id = id, Aim = aim }))
			end
		end,
	})
	entry.Runner = runner
	entry.Character = character
	return runner
end

-- what's in the hand as far as this client can tell, the way the server works it out: the tool of a prop is out, the
-- avatar is up + no ability has the hand. the player sees their own prop at once, the server has the last word by
-- taking the tool back
local function refresh(self: PropService)
	local character = Players.LocalPlayer.Character
	local heldTool: Tool? = nil
	local isFree = character ~= nil
		and not AttributeDefinition.get(character, AttributeDefinition.IsDead)
		and not (AbilityService.IsInitialized and AbilityService:GetIfEngaged())
	if isFree then
		for tool in self._Entries do
			if tool.Parent == character then
				heldTool = tool
			end
		end
	end
	if heldTool == self._HeldTool then
		return
	end
	local stowed = if self._HeldTool then self._Entries[self._HeldTool] else nil
	if stowed and stowed.Runner then
		stowed.Runner:Stow()
	end
	self._HeldTool = heldTool
	local drawn = if heldTool then self._Entries[heldTool] else nil
	if drawn and character then
		getRunner(drawn, character):Draw()
	end
end

local function remove(self: PropService, tool: Tool)
	local entry = self._Entries[tool]
	if not entry then
		return
	end
	self._Entries[tool] = nil
	for _, v in entry.Connections do
		v:Disconnect()
	end
	if entry.Runner then
		entry.Runner:Destroy()
	end
	refresh(self)
end

-- a click with it out. a prop has the one input + the engine tells it for every device
local function onActivated(self: PropService, entry: Entry)
	local character = Players.LocalPlayer.Character
	local runner = entry.Runner
	if self._HeldTool ~= entry.Tool or not runner or not character then
		return
	end
	-- somebody who's dead or sat in a menu starts nothing new
	if
		AttributeDefinition.get(character, AttributeDefinition.IsDead)
		or AttributeDefinition.get(character, AttributeDefinition.IsInMenu)
	then
		return
	end
	runner:Use(Aim.get(character))
end

-- the tool of a prop says which it is, anything else in the hotbar is somebody else's
local function add(self: PropService, inst: Instance)
	if not inst:IsA("Tool") or self._Entries[inst] then
		return
	end
	local id = inst:GetAttribute(PropDefinition.TOOL_ID_ATTRIBUTE)
	if type(id) ~= "string" or PropDefinition.get(id).IsErr then
		return
	end
	local entry: Entry = {
		Id = id,
		Tool = inst,
		Runner = nil,
		Character = nil,
		Connections = {},
	}
	self._Entries[inst] = entry
	table.insert(
		entry.Connections,
		inst.Activated:Connect(function()
			onActivated(self, entry)
		end)
	)
	-- it's got out + put away by being moved, + it's gone for good once the server takes it
	table.insert(
		entry.Connections,
		inst.AncestryChanged:Connect(function()
			if inst:IsDescendantOf(game) then
				refresh(self)
			else
				remove(self, inst)
			end
		end)
	)
	refresh(self)
end

local function watchBackpack(self: PropService, backpack: Instance)
	for _, v in self._BackpackConnections do
		v:Disconnect()
	end
	self._BackpackConnections = {
		backpack.ChildAdded:Connect(function(child: Instance)
			add(self, child)
		end),
	}
	for _, child in backpack:GetChildren() do
		add(self, child)
	end
end

local function watchCharacter(self: PropService, character: Model)
	for _, v in self._CharacterConnections do
		v:Disconnect()
	end
	self._CharacterConnections = {
		character.ChildAdded:Connect(function(child: Instance)
			add(self, child)
		end),
		character:GetAttributeChangedSignal(AttributeDefinition.IsDead.Name):Connect(function()
			refresh(self)
		end),
	}
	for _, child in character:GetChildren() do
		add(self, child)
	end
	refresh(self)
end
-- Class
local PropService = {} :: PropServiceImpl
PropService.__index = PropService

-- the client halves of the props the local player carries: what they hold is shown to them the moment they get it
-- out + a click with it starts a use here as it's told to the server. nothing that matters is decided here
return ServiceLocker(function(): PropService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	assert(AbilityService.IsInitialized, `the ability service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Entries = {},
		_HeldTool = nil :: Tool?,
		_BackpackConnections = {},
		_CharacterConnections = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, PropService)

	-- a prop that's picked while an ability is engaged goes straight back, before the server hears of it
	AbilityService:KeepHand()
	local engagedConnection = AbilityService.EngagedChanged:Connect(function()
		refresh(self)
	end)
	local localPlayer = Players.LocalPlayer
	-- the engine hands out a new backpack with every avatar
	table.insert(
		self._Connections,
		localPlayer.ChildAdded:Connect(function(child: Instance)
			if child:IsA("Backpack") then
				watchBackpack(self, child)
			end
		end)
	)
	table.insert(
		self._Connections,
		localPlayer.CharacterAdded:Connect(function(character: Model)
			watchCharacter(self, character)
		end)
	)
	local backpack = localPlayer:FindFirstChildOfClass("Backpack")
	if backpack then
		watchBackpack(self, backpack)
	end
	if localPlayer.Character then
		watchCharacter(self, localPlayer.Character)
	end

	table.insert(self._CleanUpCallbacks, function()
		engagedConnection:Disconnect()
		for _, v in self._BackpackConnections do
			v:Disconnect()
		end
		for _, v in self._CharacterConnections do
			v:Disconnect()
		end
		for tool in self._Entries do
			remove(self, tool)
		end
	end)

	return self
end, function(self: PropService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
