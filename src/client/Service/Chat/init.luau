--!strict
-- Services
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local Line = require("@self/Line")
-- Types
type Rule = Line.Rule
type Speaker = Line.Speaker
-- a line of the log, by the message it's of: the engine may tell of one more than once
type Entry = {
	Id: string,
	Text: string,
}
type ChatServiceImpl = {
	__index: ChatServiceImpl,
	-- what the log of the game reads, the newest last. the same table until the next change. always empty in a game
	-- that leaves its lines to the window of the engine
	GetLines: (self: ChatService) -> { string },
	GetIfMuting: (self: ChatService) -> boolean,
	-- the local player's own, for the visit: it only ever decides about the lines that come in after it
	SetMuting: (self: ChatService, isMuting: boolean) -> (),
}
export type ChatService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- the log or the muting isn't what it was
		Changed: Signal.Signal<>,
		_Entries: { Entry },
		_Lines: { string },
		_IsMuting: boolean,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: ChatServiceImpl
))
-- Constants
-- the engine has one say per client in what a line reads as, so every game's rule is decided here
local RULE: Rule = GameDefinition.pick({
	-- "<name>: <line>", + whoever mutes reads nothing of those of the other mode
	shl1 = function(): Rule
		return {
			PrefixFormat = "%s:",
			IsMutedByMode = true,
		}
	end,
	shl2 = function(): Rule
		return {
			PrefixFormat = "%s:",
			IsMutedByMode = false,
		}
	end,
	-- its fork of the old chat wrote "[<name>]:", in the color of the side + in white for a civilian
	shl3 = function(): Rule
		return {
			PrefixFormat = "[%s]:",
			IsMutedByMode = false,
			CivilianColor = Color3.new(1, 1, 1),
		}
	end,
})
assert(Line.Rule(RULE))
-- how many lines a game with a log of its own keeps in it. such a game reads its chat there + nowhere else: the
-- window + the bubbles of the engine are off, the bar a line is typed into stays. nil leaves all of it to the engine
local LOG_LIMIT: number? = GameDefinition.tune(nil :: number?, {
	shl1 = 12,
})
local NO_LINES: { string } = table.freeze({})
-- Variables
-- References
-- Private Functions
local function getSpeaker(source: TextSource?): Speaker?
	local player = if source then Players:GetPlayerByUserId(source.UserId) else nil
	if not player then
		return nil
	end
	local team = player.Team
	return {
		Name = player.Name,
		Alias = AttributeDefinition.get(player, AttributeDefinition.ActivePersonaName),
		IdentityKey = AttributeDefinition.get(player, AttributeDefinition.ActiveIdentityKey),
		IsPeaceful = AttributeDefinition.get(player, AttributeDefinition.IsPlayerPeaceful) == true,
		SideColor = if team then team.TeamColor.Color else nil,
	}
end

-- the line of a message that's in already is written over, so one the engine tells of twice is there once
local function log(self: ChatService, id: string, text: string, limit: number)
	local entries = self._Entries
	local isFound = false
	for _, entry in entries do
		if entry.Id == id then
			entry.Text = text
			isFound = true
			break
		end
	end
	if not isFound then
		table.insert(entries, {
			Id = id,
			Text = text,
		})
		while #entries > limit do
			table.remove(entries, 1)
		end
	end
	local lines: { string } = {}
	for index, entry in entries do
		lines[index] = entry.Text
	end
	table.freeze(lines)
	self._Lines = lines
	self.Changed:Fire()
end

-- a line is judged once, as it arrives: the old game went over its whole log again with every message
local function onMessage(self: ChatService, message: TextChatMessage): TextChatMessageProperties
	local properties = Instance.new("TextChatMessageProperties")
	local speaker = getSpeaker(message.TextSource)
	if not speaker then
		-- the engine's own, or of somebody who left since: nothing of it is touched
		if LOG_LIMIT and message.Status == Enum.TextChatMessageStatus.Success then
			log(self, message.MessageId, message.Text, LOG_LIMIT)
		end
		return properties
	end
	local line = Line.get(speaker, message.Text, {
		IsPeaceful = AttributeDefinition.get(Players.LocalPlayer, AttributeDefinition.IsPlayerPeaceful) == true,
		IsMuting = self._IsMuting,
	}, RULE)
	properties.PrefixText = Line.getPrefixText(line, RULE)
	-- what was said is only written over where it isn't what's read: left alone it stays the engine's to make safe
	if line.Text ~= message.Text then
		properties.Text = line.Text
	end
	-- a line of one's own comes by twice, the first time before the server passed it
	if LOG_LIMIT and message.Status == Enum.TextChatMessageStatus.Success then
		log(self, message.MessageId, Line.getLogText(line), LOG_LIMIT)
	end
	return properties
end

-- the window + the bubbles the engine would read the same lines out in, whenever they get here
local function setStockOff(child: Instance)
	if child:IsA("ChatWindowConfiguration") or child:IsA("BubbleChatConfiguration") then
		-- the checker has no class the two share their switch by
		(child :: any).Enabled = false
	end
end
-- Class
local ChatService = {} :: ChatServiceImpl
ChatService.__index = ChatService

function ChatService:GetLines(): { string }
	assert(self.IsInitialized, `the chat service isn't initialized`)
	return self._Lines
end

function ChatService:GetIfMuting(): boolean
	assert(self.IsInitialized, `the chat service isn't initialized`)
	return self._IsMuting
end

function ChatService:SetMuting(isMuting: boolean)
	assert(self.IsInitialized, `the chat service isn't initialized`)
	if self._IsMuting == isMuting then
		return
	end
	self._IsMuting = isMuting
	self.Changed:Fire()
end

-- who speaks goes by who they play, in the window of the engine + in a log of the game's own. nothing of it is the
-- server's: what a line reads as is each client's to say, from what every player tells of themselves
return ServiceLocker(function(): ChatService
	local self = setmetatable({
		IsInitialized = true :: true,
		Changed = Signal.new() :: Signal.Signal<>,
		_Entries = {} :: { Entry },
		_Lines = NO_LINES,
		_IsMuting = false,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, ChatService)

	TextChatService.OnIncomingMessage = function(message: TextChatMessage): TextChatMessageProperties
		return onMessage(self, message)
	end
	table.insert(self._CleanUpCallbacks, function()
		-- the checker has no callback that's taken back
		(TextChatService :: any).OnIncomingMessage = nil
	end)
	if LOG_LIMIT then
		for _, child in TextChatService:GetChildren() do
			setStockOff(child)
		end
		table.insert(self._Connections, TextChatService.ChildAdded:Connect(setStockOff))
	end
	table.insert(self._CleanUpCallbacks, function()
		self.Changed:Destroy()
	end)

	return self
end, function(self: ChatService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
