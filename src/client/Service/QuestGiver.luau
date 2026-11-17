--!strict
-- Services
local Chat = game:GetService("Chat")
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local Workspace = game:GetService("Workspace")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Future = TypeUnionLib.Future
-- Modules
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local QuestDefinition = require("@game/ReplicatedStorage/Shared/Definition/Quest")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Types
type QuestGiverServiceImpl = {
	__index: QuestGiverServiceImpl,
}
export type QuestGiverService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_IsRequesting: boolean, -- the server hasn't answered the last choice yet
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: QuestGiverServiceImpl
))
-- Constants
local DIALOG = QuestDefinition.DIALOG
local DIALOG_PATH = `{QuestDefinition.QUEST_GIVER_PATH}/Head/Dialog`
-- the lines the server turns a quest down with, anything else it answers with isn't the quest giver talking
local REFUSALS: { string } = table.freeze({ DIALOG.HAS_QUEST, DIALOG.NO_PLAYERS, DIALOG.NO_TARGET })
local CHAT_COLOR = Enum.ChatColor.Blue
-- Variables
-- References
-- Private Functions
local isQuestType = Type.literal(table.unpack(PseudoEnum.getEnumItems("QuestType")))

-- a bubble over the quest giver that only this client sees, the same way the dialog itself talks
local function say(speaker: Instance, line: string)
	local success, msg = pcall(function()
		if TextChatService.ChatVersion == Enum.ChatVersion.TextChatService then
			TextChatService:DisplayBubble(speaker, line)
		else
			Chat:Chat(speaker, line, CHAT_COLOR)
		end
	end)
	if not success then
		warn(`quest giver err: {msg}`)
	end
end

-- the server picks the goal of a quest, so what the quest giver answers is only known once it did
local function request(self: QuestGiverService, speaker: Instance, questType: PseudoEnum.QuestType)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	if self._IsRequesting then
		return
	end
	self._IsRequesting = true
	task.spawn(function()
		local questRes = NetworkService:Invoke(RemoteDefinition.StartQuest, questType)
		if not self.IsInitialized then
			return
		end
		self._IsRequesting = false
		if questRes.IsErr then
			if table.find(REFUSALS, questRes.Value) then
				say(speaker, questRes.Value)
			else
				-- a request that broke on the way isn't his to explain, the player is told to come back
				warn(`quest err: {questRes.Value}`)
				say(speaker, DIALOG.NO_TARGET)
			end
			return
		end
		say(speaker, questRes.Value.Instruction)
		if ShellService.IsInitialized then
			ShellService:FireTutorialTrigger("QuestStarted")
		end
	end)
end

-- a dialog answers a choice the moment it's picked, so its answers are blanked + the server's line is said later
local function bind(self: QuestGiverService, dialog: Dialog)
	dialog.InitialPrompt = DIALOG.GREETING
	dialog.GoodbyeDialog = DIALOG.GOODBYE
	local function prepChoice(inst: Instance)
		if not inst:IsA("DialogChoice") or not isQuestType(inst.Name) then
			return
		end
		inst.UserDialog = QuestDefinition.get(inst.Name :: PseudoEnum.QuestType).Prompt
		inst.ResponseDialog = ""
	end
	for _, inst in dialog:GetChildren() do
		prepChoice(inst)
	end
	-- the choices may still be on their way in behind the dialog
	table.insert(self._Connections, dialog.ChildAdded:Connect(prepChoice))
	table.insert(
		self._Connections,
		dialog.DialogChoiceSelected:Connect(function(player: Player, choice: DialogChoice)
			local speaker = dialog.Parent
			if player ~= Players.LocalPlayer or not speaker or not isQuestType(choice.Name) then
				return
			end
			request(self, speaker, choice.Name :: PseudoEnum.QuestType)
		end)
	)
end

local function hide(self: QuestGiverService, giver: Instance)
	local parent = giver.Parent
	giver.Parent = nil
	table.insert(self._CleanUpCallbacks, function()
		-- unless the map he stood in is gone by then
		if parent and parent:IsDescendantOf(Workspace) then
			giver.Parent = parent
		end
	end)
end
-- Class
local QuestGiverService = {} :: QuestGiverServiceImpl
QuestGiverService.__index = QuestGiverService

return ServiceLocker(function(): QuestGiverService
	if BUILD_CONFIG.QUESTS_ENABLED then
		assert(NetworkService.IsInitialized, `the network service isn't initialized`)
		assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	end

	local self = setmetatable({
		IsInitialized = true :: true,
		_IsRequesting = false,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, QuestGiverService)

	-- the map may still be loading + not every map has a quest giver, so nothing waits on him
	task.spawn(function()
		local path = if BUILD_CONFIG.QUESTS_ENABLED then DIALOG_PATH else QuestDefinition.QUEST_GIVER_PATH
		local instF = Future.awaitUntil(IndexUtil.getFuturePath(path), function(): boolean
			return not self.IsInitialized
		end)
		if not instF.IsDone or not self.IsInitialized then
			return
		end
		local inst = instF.Value
		if not BUILD_CONFIG.QUESTS_ENABLED then
			hide(self, inst)
		elseif inst:IsA("Dialog") then
			bind(self, inst)
		else
			warn(`the quest giver has no dialog to talk through`)
		end
	end)

	return self
end, function(self: QuestGiverService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
