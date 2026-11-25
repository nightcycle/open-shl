--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local AbilityService = require("@game/ServerScriptService/Server/Service/Ability")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local AvatarService = require("@game/ServerScriptService/Server/Service/Avatar")
local HalfUtil = require("@self/Half")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local PropDefinition = require("@game/ReplicatedStorage/Shared/Definition/Prop")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local Runner = require("@game/ReplicatedStorage/Shared/Prop/Runner")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
local ToolUtil = require("@game/ServerScriptService/Server/Util/Tool")
local VFXService = require("@game/ServerScriptService/Server/Service/VFX")
-- Types
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
type Runner = Runner.Runner
type Report = PropType.Report
-- one prop an avatar carries: its slot of the hotbar + the half the server runs of it
type Entry = {
	Tool: Tool,
	Runner: Runner,
	Connections: { RBXScriptConnection },
}
-- what one avatar carries, gone with it
type Carry = {
	Character: Model,
	Entries: { [string]: Entry },
	HeldId: string?,
	Connections: { RBXScriptConnection },
}
type PropServiceImpl = {
	__index: PropServiceImpl,
	-- hands the avatar of the player one prop for as long as it lives. true if it did: it's a prop of the game, the
	-- avatar is up + doesn't carry one already
	Grant: (self: PropService, player: Player, id: string) -> boolean,
	-- takes one prop off the avatar of the player. true if it carried one
	Take: (self: PropService, player: Player, id: string) -> boolean,
	-- takes every prop off the avatar of the player
	Clear: (self: PropService, player: Player) -> (),
	-- the prop the server counts as in the hand of the player, nil for an empty hand
	GetHeldId: (self: PropService, player: Player) -> string?,
	GetIfCarried: (self: PropService, player: Player, id: string) -> boolean,
}
export type PropService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Carries: { [Player]: Carry },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: PropServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
-- the one place that says what's in a hand. a prop is held while its tool is out, its avatar is up + no ability has
-- the hand. the avatar says so for everybody to read
local function refresh(self: PropService, player: Player)
	local carry = self._Carries[player]
	if not carry then
		return
	end
	local character = carry.Character
	local equippedId: string? = nil
	for id, entry in carry.Entries do
		if entry.Tool.Parent == character then
			equippedId = id
		end
	end
	local isFree = not AttributeDefinition.get(character, AttributeDefinition.IsDead)
		and not (AbilityService.IsInitialized and AbilityService:GetIfEngaged(player))
	local heldId = if isFree then equippedId else nil
	if heldId == carry.HeldId then
		return
	end
	local stowed = if carry.HeldId then carry.Entries[carry.HeldId] else nil
	if stowed then
		stowed.Runner:Stow()
	end
	carry.HeldId = heldId
	AttributeDefinition.set(character, AttributeDefinition.HeldPropId, heldId)
	local drawn = if heldId then carry.Entries[heldId] else nil
	if drawn then
		drawn.Runner:Draw()
	end
end

-- everything the avatar wears is about to change: the tool goes back where it came from. an ability that takes the
-- hand sends it back by itself
local function putAway(self: PropService, player: Player)
	local carry = self._Carries[player]
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not carry or not backpack then
		return
	end
	for _, entry in carry.Entries do
		if entry.Tool.Parent == carry.Character then
			entry.Tool.Parent = backpack
		end
	end
	refresh(self, player)
end

-- a use that's on gives nothing: what waits at its end goes with the runner
local function take(self: PropService, player: Player, id: string): boolean
	local carry = self._Carries[player]
	local entry = if carry then carry.Entries[id] else nil
	if not carry or not entry then
		return false
	end
	carry.Entries[id] = nil
	for _, v in entry.Connections do
		v:Disconnect()
	end
	entry.Runner:Destroy()
	entry.Tool:Destroy()
	refresh(self, player)
	return true
end

local function clear(self: PropService, player: Player)
	local carry = self._Carries[player]
	if not carry then
		return
	end
	for id in carry.Entries do
		take(self, player, id)
	end
	self._Carries[player] = nil
	for _, v in carry.Connections do
		v:Disconnect()
	end
end

-- what the avatar carries, started as it's handed its first prop. it ends with the body: nothing is carried over
-- to the next one
local function getCarry(self: PropService, player: Player, character: Model): Carry
	local current = self._Carries[player]
	if current and current.Character == character then
		return current
	end
	clear(self, player)
	local carry: Carry = {
		Character = character,
		Entries = {},
		HeldId = nil,
		Connections = {},
	}
	self._Carries[player] = carry
	local function drop()
		if self.IsInitialized and self._Carries[player] == carry then
			clear(self, player)
		end
	end
	table.insert(
		carry.Connections,
		character:GetAttributeChangedSignal(AttributeDefinition.IsDead.Name):Connect(function()
			if AttributeDefinition.get(character, AttributeDefinition.IsDead) then
				drop()
			end
		end)
	)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		table.insert(carry.Connections, humanoid.Died:Connect(drop))
	end
	table.insert(
		carry.Connections,
		character.AncestryChanged:Connect(function()
			if not character:IsDescendantOf(game) then
				drop()
			end
		end)
	)
	return carry
end

local function onReported(self: PropService, player: Player, report: Report)
	local carry = self._Carries[player]
	-- only what the server counts as held is used, whatever the client has in its hand
	if not carry or carry.Character ~= player.Character or report.Id ~= carry.HeldId then
		return
	end
	-- somebody who sits in a menu starts nothing new
	if AttributeDefinition.get(carry.Character, AttributeDefinition.IsInMenu) then
		return
	end
	local entry = carry.Entries[report.Id]
	if entry then
		entry.Runner:Use(report.Aim)
	end
end
-- Class
local PropService = {} :: PropServiceImpl
PropService.__index = PropService

function PropService:Grant(player: Player, id: string): boolean
	assert(self.IsInitialized, `the prop service isn't initialized`)
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	local definitionRes = PropDefinition.get(id)
	if definitionRes.IsErr then
		warn(`prop err: {definitionRes.Value}`)
		return false
	end
	local definition = definitionRes.Value
	local character = player.Character
	local backpack = player:FindFirstChildOfClass("Backpack")
	if not character or not backpack or AttributeDefinition.get(character, AttributeDefinition.IsDead) then
		return false
	end
	local carry = getCarry(self, player, character)
	-- one of each for as long as the avatar lives
	if carry.Entries[id] then
		return false
	end
	local tool = ToolUtil.new(definition.Name, definition.Icon, PropDefinition.TOOL_ID_ATTRIBUTE, id)
	local runner = HalfUtil.new(id, character, player, VFXService:NewScope(player, character))
	carry.Entries[id] = {
		Tool = tool,
		Runner = runner,
		Connections = {
			tool.Equipped:Connect(function()
				refresh(self, player)
			end),
			tool.Unequipped:Connect(function()
				refresh(self, player)
			end),
		},
	}
	tool.Parent = backpack
	return true
end

function PropService:Take(player: Player, id: string): boolean
	assert(self.IsInitialized, `the prop service isn't initialized`)
	return take(self, player, id)
end

function PropService:Clear(player: Player)
	assert(self.IsInitialized, `the prop service isn't initialized`)
	clear(self, player)
end

-- held, not carried: one that's put away is in nobody's hand, + neither is one whose avatar an ability has the hand of
function PropService:GetHeldId(player: Player): string?
	assert(self.IsInitialized, `the prop service isn't initialized`)
	local carry = self._Carries[player]
	if not carry or carry.Character ~= player.Character then
		return nil
	end
	return carry.HeldId
end

function PropService:GetIfCarried(player: Player, id: string): boolean
	assert(self.IsInitialized, `the prop service isn't initialized`)
	local carry = self._Carries[player]
	return carry ~= nil and carry.Character == player.Character and carry.Entries[id] ~= nil
end

-- what an avatar holds that isn't a power: a tool in the hotbar + the server half of its prop, for one life. the hand
-- is the server's to say: only an empty one takes a prop, + an ability that takes the hand has it at once
return ServiceLocker(function(): PropService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(VFXService.IsInitialized, `the vfx service isn't initialized`)
	assert(AbilityService.IsInitialized, `the ability service isn't initialized`)
	assert(AvatarService.IsInitialized, `the avatar service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Carries = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, PropService)

	-- a prop that's picked while an ability is engaged goes straight back, the ability never hears of it
	AbilityService:KeepHand()
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.PropReported, function(player: Player, report: Report)
			onReported(self, player, report)
		end)
	)
	local engagedConnection = AbilityService.EngagedChanged:Connect(function(player: Player)
		refresh(self, player)
	end)
	local grantedConnection = AbilityService.Granted:Connect(function(player: Player, character: Model)
		local carry = self._Carries[player]
		if carry and carry.Character ~= character then
			clear(self, player)
		else
			-- the limbs are about to be swapped out, what's held by one would be left behind
			putAway(self, player)
		end
	end)
	-- a new avatar starts out with nothing, whatever became of the one before
	local spawnedConnection = AvatarService.Spawned:Connect(function(player: Player, character: Model)
		local carry = self._Carries[player]
		if carry and carry.Character ~= character then
			clear(self, player)
		end
	end)
	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		clear(self, player)
	end)
	table.insert(self._CleanUpCallbacks, function()
		engagedConnection:Disconnect()
		grantedConnection:Disconnect()
		spawnedConnection:Disconnect()
		removingConnection:Disconnect()
		for player in self._Carries do
			clear(self, player)
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
