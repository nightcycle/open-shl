--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local EconomyService = require("@game/ServerScriptService/Server/Service/Economy")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local NetworkService = require("@game/ServerScriptService/Server/Service/Network")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local QuestDefinition = require("@game/ReplicatedStorage/Shared/Definition/Quest")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local SessionService = require("@game/ServerScriptService/Server/Service/Session")
-- Types
local QuestType = require("@game/ReplicatedStorage/Shared/Type/Quest")
type Result<V, E> = TypeUnionLib.Result<V, E>
type QuestState = QuestType.QuestState
type QuestStatus = QuestType.QuestStatus
type QuestReward = QuestType.QuestReward
-- the goal + the reward never leave the server, the owner only gets the state
type Quest = {
	Type: PseudoEnum.QuestType,
	Instruction: string,
	Reward: QuestReward, -- rolled when the quest started, paid only when it's won
	EndTime: number, -- on the clock of os.clock
	Item: BasePart?, -- what a find quest is after
	Target: Player?, -- who a target quest is after
	Thread: thread?, -- counts the quest down
	Connections: { RBXScriptConnection },
}
type QuestServiceImpl = {
	__index: QuestServiceImpl,
}
export type QuestService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Random: Random,
		_Quests: { [Player]: Quest },
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: QuestServiceImpl
))
-- Constants
local DIALOG = QuestDefinition.DIALOG
local TICK_DURATION = 1
-- Variables
-- References
-- Private Functions
local function newState(quest: Quest, status: QuestStatus): QuestState
	return {
		Type = quest.Type,
		Instruction = quest.Instruction,
		SecondsRemaining = math.max(0, math.ceil(quest.EndTime - os.clock())),
		Status = status,
	}
end

-- the session only holds a quest while it runs, its owner is told about every state including the last
local function replicate(player: Player, state: QuestState)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local questRes = SessionService:SetQuest(player, if state.Status == "Active" then state else nil)
	if questRes.IsErr then
		warn(`quest err: {questRes.Value}`)
	end
	NetworkService:Fire(RemoteDefinition.QuestChanged, player, state)
end

-- an item is hidden in the map until somebody is sent after it, everybody can see + bump into it while it's out
local function setItemShown(item: BasePart, isShown: boolean)
	item.Transparency = if isShown then 0 else 1
	item.CanCollide = isShown
end

-- one that's out for somebody else stays theirs. the map is looked up when it's needed so a map without the
-- items doesn't hold the server up
local function getFindItem(self: QuestService): BasePart?
	local folder = IndexUtil.findFirstPath(QuestDefinition.FIND_ITEM_PATH)
	if not folder then
		warn(`the map has no find quest items`)
		return nil
	end
	local items: { BasePart } = {}
	for _, inst in folder:GetChildren() do
		if not inst:IsA("BasePart") or QuestDefinition.getFindItemName(inst.Name).IsNone then
			continue
		end
		local isOut = false
		for _, quest in self._Quests do
			if quest.Item == inst then
				isOut = true
				break
			end
		end
		if not isOut then
			table.insert(items, inst)
		end
	end
	if #items == 0 then
		return nil
	end
	return items[self._Random:NextInteger(1, #items)]
end

-- anybody else who is out in the world + not sat in a menu
local function getTarget(self: QuestService, player: Player): Player?
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	local targets: { Player } = {}
	for _, other in Players:GetPlayers() do
		if
			other ~= player
			and other.Character
			and SessionService:Get(other).IsSome
			and not SessionService:GetIfInMenu(other)
		then
			table.insert(targets, other)
		end
	end
	if #targets == 0 then
		return nil
	end
	return targets[self._Random:NextInteger(1, #targets)]
end

local function pay(player: Player, quest: Quest)
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	local reward = quest.Reward
	local grantRes = EconomyService:Grant(player, reward.Currency, reward.Amount)
	if grantRes.IsErr then
		warn(`quest reward err: {grantRes.Value}`)
	end
end

local function finish(self: QuestService, player: Player, isSuccess: boolean)
	local quest = self._Quests[player]
	if not quest then
		return
	end
	self._Quests[player] = nil
	for _, v in quest.Connections do
		v:Disconnect()
	end
	if quest.Thread and coroutine.status(quest.Thread) == "suspended" then
		task.cancel(quest.Thread)
	end
	if quest.Item then
		setItemShown(quest.Item, false)
	end
	replicate(player, newState(quest, if isSuccess then "Succeeded" else "Failed"))
	if isSuccess then
		pay(player, quest)
	end
end

-- todo: combat wins a target quest
local function onDefeat(self: QuestService, victim: Player)
	local quest = self._Quests[victim]
	if quest and quest.Type == PseudoEnum.QuestType.Survive then
		finish(self, victim, false)
	end
end

-- nothing takes health down yet, so only a reset, a fall off the map or a hazard gets here
local function watchAvatar(self: QuestService, player: Player, character: Model, connections: { RBXScriptConnection })
	table.insert(
		connections,
		character:GetAttributeChangedSignal(AttributeDefinition.Health.Name):Connect(function()
			if AttributeDefinition.get(character, AttributeDefinition.Health) <= 0 then
				onDefeat(self, player)
			end
		end)
	)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		table.insert(
			connections,
			humanoid.Died:Connect(function()
				onDefeat(self, player)
			end)
		)
	end
end

-- the server picks the goal + rolls the reward, an error is the line the quest giver turns the player down with
local function start(self: QuestService, player: Player, questType: PseudoEnum.QuestType): Result<QuestState, string>
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	if not ModeDefinition.getIfQuestsEnabled() then
		return Result.err(`quests are off in this mode`)
	end
	if SessionService:Get(player).IsNone then
		return Result.err(`{player.Name} has no session`)
	end
	if self._Quests[player] then
		return Result.err(DIALOG.HAS_QUEST)
	end
	local definition = QuestDefinition.get(questType)
	if #Players:GetPlayers() < definition.MinPlayerCount then
		return Result.err(DIALOG.NO_PLAYERS)
	end

	local item: BasePart?
	local target: Player?
	local goalName: string?
	if questType == PseudoEnum.QuestType.Find then
		item = getFindItem(self)
		if not item then
			return Result.err(DIALOG.NO_TARGET)
		end
		local nameOpt = QuestDefinition.getFindItemName(item.Name)
		goalName = if nameOpt.IsSome then nameOpt.Value else nil
	elseif questType == PseudoEnum.QuestType.Target then
		target = getTarget(self, player)
		if not target then
			return Result.err(DIALOG.NO_TARGET)
		end
		-- the target goes by the name on their name tag, the way everybody else gets to know them
		goalName = QuestDefinition.getTargetAlias(
			AttributeDefinition.get(target.Character, AttributeDefinition.PersonaName),
			target.Name
		)
	end
	local instructionRes = QuestDefinition.formatInstruction(questType, goalName)
	if instructionRes.IsErr then
		return instructionRes
	end

	local quest: Quest = {
		Type = questType,
		Instruction = instructionRes.Value,
		Reward = QuestDefinition.rollReward(questType, self._Random),
		EndTime = os.clock() + definition.Duration,
		Item = item,
		Target = target,
		Connections = {},
	}
	self._Quests[player] = quest

	if item then
		setItemShown(item, true)
		table.insert(
			quest.Connections,
			item.Touched:Connect(function(hit: BasePart)
				local character = player.Character
				if character and hit:IsDescendantOf(character) then
					finish(self, player, true)
				end
			end)
		)
	end
	if questType == PseudoEnum.QuestType.Survive then
		-- the avatar the player has now + every one they respawn as
		table.insert(
			quest.Connections,
			player.CharacterAdded:Connect(function(character: Model)
				watchAvatar(self, player, character, quest.Connections)
			end)
		)
		if player.Character then
			watchAvatar(self, player, player.Character, quest.Connections)
		end
	end
	quest.Thread = task.spawn(function()
		while true do
			task.wait(TICK_DURATION)
			if os.clock() >= quest.EndTime then
				break
			end
			replicate(player, newState(quest, "Active"))
		end
		finish(self, player, definition.IsTimeoutSuccess)
	end)

	local state = newState(quest, "Active")
	replicate(player, state)
	return Result.ok(state)
end
-- Class
local QuestService = {} :: QuestServiceImpl
QuestService.__index = QuestService

return ServiceLocker(function(): QuestService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(SessionService.IsInitialized, `the session service isn't initialized`)
	assert(EconomyService.IsInitialized, `the economy service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		_Random = Random.new(),
		_Quests = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, QuestService)

	-- both remotes are answered whatever the mode is, with the quests off every start is turned down
	NetworkService:Handle(
		RemoteDefinition.StartQuest,
		function(player: Player, questType: PseudoEnum.QuestType): Result<QuestState, string>
			return start(self, player, questType)
		end
	)
	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.CancelQuest, function(player: Player)
			-- giving up fails the quest
			finish(self, player, false)
		end)
	)

	local removingConnection = SessionService.Removing:Connect(function(player: Player)
		finish(self, player, false)
		-- nobody is left to defeat
		for other, quest in self._Quests do
			if quest.Target == player then
				finish(self, other, false)
			end
		end
	end)
	table.insert(self._CleanUpCallbacks, function()
		removingConnection:Disconnect()
		for player in self._Quests do
			finish(self, player, false)
		end
	end)

	return self
end, function(self: QuestService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
