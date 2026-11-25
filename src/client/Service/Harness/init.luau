--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local EventCommand = require("@game/ReplicatedStorage/Shared/Harness/Command/Event")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local Log = require("@game/ReplicatedStorage/Shared/Harness/Log")
local Watch = require("@self/Watch")
-- Types
type Command = Harness.Command
type Answer = Harness.Answer
type Bridge = Harness.Bridge
-- the commands of one area, beside the service they drive. an area whose service the game doesn't start is never loaded
type Area = {
	Name: string,
	IsFeatured: boolean?, -- nil when every game has it
	Load: () -> { list: () -> { Command } },
}
type HarnessServiceImpl = {
	__index: HarnessServiceImpl,
	-- what the bindable answers with: a command of this client by its name + the table of its arguments. yields the
	-- way the command does, never throws
	Invoke: (self: HarnessService, name: unknown, args: unknown) -> Answer,
}
export type HarnessService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Bridge: Bridge,
		_CleanUpCallbacks: { () -> () },
	},
	{} :: HarnessServiceImpl
))
-- Constants
local LOG_CAPACITY = 2048
local FEATURES = GameDefinition.FEATURES
-- one module per area, each beside the service it drives + gated the way that service is in the list of services
local AREAS: { Area } = table.freeze({
	{
		Name = "Shell",
		Load = function()
			return require("@self/Command/Shell")
		end,
	},
	{
		Name = "Player",
		Load = function()
			return require("@self/Command/Player")
		end,
	},
	{
		Name = "Boot",
		Load = function()
			return require("@self/Command/Boot")
		end,
	},
	{
		Name = "Remote",
		Load = function()
			return require("@self/Command/Remote")
		end,
	},
	{
		Name = "Acrobatics",
		IsFeatured = FEATURES.Acrobatics,
		Load = function()
			return require("@self/Command/Acrobatics")
		end,
	},
})
-- Variables
-- References
local PlayerScripts = IndexUtil.waitForLocalPath(Players.LocalPlayer, "PlayerScripts")
-- Private Functions
-- Class
local HarnessService = {} :: HarnessServiceImpl
HarnessService.__index = HarnessService

function HarnessService:Invoke(name: unknown, args: unknown): Answer
	return self._Bridge(name, args)
end

-- what an agent drives one client of a running game through, in a place that was built for it + nowhere else. it's a
-- BindableFunction this client makes in its own PlayerScripts: the server doesn't see in there, no other client does,
-- + nothing of this is a remote. whoever invokes it from outside of the game's scripts lands in the modules the
-- client itself runs
return ServiceLocker(function(): HarnessService
	local log = Log.new(LOG_CAPACITY)
	local commands: { Command } = {}
	for _, area in AREAS do
		if area.IsFeatured ~= false then
			for _, command in area.Load().list() do
				table.insert(commands, command)
			end
		end
	end
	for _, command in EventCommand.list(log, Watch.KINDS) do
		table.insert(commands, command)
	end

	local self = setmetatable({
		IsInitialized = true :: true,
		_Bridge = Harness.newBridge(commands),
		_CleanUpCallbacks = {},
	}, HarnessService)

	table.insert(self._CleanUpCallbacks, Watch.start(log))

	local bindable = Instance.new("BindableFunction")
	bindable.Name = Harness.BINDABLE_NAME
	bindable.OnInvoke = function(name: unknown, args: unknown): Answer
		return self:Invoke(name, args)
	end
	bindable.Parent = PlayerScripts
	table.insert(self._CleanUpCallbacks, function()
		bindable:Destroy()
	end)

	-- what an agent looks for before it invokes anything
	print(`[harness] client ok ({#commands + 1} commands, {bindable:GetFullName()})`)

	return self
end, function(self: HarnessService)
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
