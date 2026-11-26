--!strict
-- Services
local ServerStorage = game:GetService("ServerStorage")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local Bodies = require("@self/Bodies")
local EventCommand = require("@game/ReplicatedStorage/Shared/Harness/Command/Event")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
local Log = require("@game/ReplicatedStorage/Shared/Harness/Log")
local Watch = require("@self/Watch")
-- Types
local HarnessTypes = require("@self/Types")
type Command = Harness.Command
type Answer = Harness.Answer
type Bridge = Harness.Bridge
type Area = HarnessTypes.Area
type Context = HarnessTypes.Context
type HarnessServiceImpl = {
	__index: HarnessServiceImpl,
	-- what the bindable answers with: a command of the server by its name + the table of its arguments. yields the
	-- way the command does, never throws
	Invoke: (self: HarnessService, name: unknown, args: unknown) -> Answer,
}
export type HarnessService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Bridge: Bridge,
		_Bodies: Bodies.Bodies,
		_CleanUpCallbacks: { () -> () },
	},
	{} :: HarnessServiceImpl
))
-- Constants
local FEATURES = GameDefinition.FEATURES
-- more than a fight between two bodies fills between two reads
local LOG_CAPACITY = 2048
-- one module per area, each beside the service it drives + gated the way that service is in the list of services: an
-- area of a service this game doesn't start is never required, so neither is the service
local AREAS: { Area } = table.freeze({
	{
		Name = "Game",
		Load = function()
			return require("@self/Command/Game")
		end,
	},
	{
		Name = "Session",
		Load = function()
			return require("@self/Command/Session")
		end,
	},
	{
		Name = "Avatar",
		Load = function()
			return require("@self/Command/Avatar")
		end,
	},
	{
		Name = "Character",
		Load = function()
			return require("@self/Command/Character")
		end,
	},
	{
		Name = "Economy",
		Load = function()
			return require("@self/Command/Economy")
		end,
	},
	{
		Name = "Combat",
		Load = function()
			return require("@self/Command/Combat")
		end,
	},
	{
		Name = "Status",
		Load = function()
			return require("@self/Command/Status")
		end,
	},
	{
		Name = "Puppet",
		Load = function()
			return require("@self/Command/Puppet")
		end,
	},
	{
		Name = "Remote",
		Load = function()
			return require("@self/Command/Remote")
		end,
	},
	{
		Name = "VipServer",
		IsFeatured = FEATURES.PrivateServerToggle,
		Load = function()
			return require("@self/Command/VipServer")
		end,
	},
	{
		Name = "PlayerMode",
		IsFeatured = FEATURES.PlayerMode,
		Load = function()
			return require("@self/Command/PlayerMode")
		end,
	},
	{
		Name = "Prop",
		IsFeatured = FEATURES.Props,
		Load = function()
			return require("@self/Command/Prop")
		end,
	},
	{
		Name = "Team",
		IsFeatured = FEATURES.Teams,
		Load = function()
			return require("@self/Command/Team")
		end,
	},
	{
		Name = "Jail",
		IsFeatured = FEATURES.Teams,
		Load = function()
			return require("@self/Command/Jail")
		end,
	},
	{
		Name = "Npc",
		IsFeatured = FEATURES.Npcs,
		Load = function()
			return require("@self/Command/Npc")
		end,
	},
	{
		Name = "Crime",
		IsFeatured = FEATURES.Crime,
		Load = function()
			return require("@self/Command/Crime")
		end,
	},
})
-- Variables
-- References
-- Private Functions
-- Class
local HarnessService = {} :: HarnessServiceImpl
HarnessService.__index = HarnessService

function HarnessService:Invoke(name: unknown, args: unknown): Answer
	return self._Bridge(name, args)
end

-- what an agent drives the server of a running game through, in a place that was built for it + nowhere else. it's a
-- BindableFunction in ServerStorage: no client reaches there, + nothing of this is a remote. whoever invokes it from
-- outside of the game's scripts (the command bar, the studio mcp) lands in the modules the game itself runs
return ServiceLocker(function(): HarnessService
	local log = Log.new(LOG_CAPACITY)
	local bodies = Bodies.new(log)
	local context: Context = table.freeze({
		Log = log,
		Bodies = bodies,
	})
	local commands: { Command } = {}
	for _, area in AREAS do
		if area.IsFeatured ~= false then
			for _, command in area.Load().list(context) do
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
		_Bodies = bodies,
		_CleanUpCallbacks = {},
	}, HarnessService)

	table.insert(self._CleanUpCallbacks, Watch.start(log))

	local bindable = Instance.new("BindableFunction")
	bindable.Name = Harness.BINDABLE_NAME
	bindable.OnInvoke = function(name: unknown, args: unknown): Answer
		return self:Invoke(name, args)
	end
	bindable.Parent = ServerStorage
	table.insert(self._CleanUpCallbacks, function()
		bindable:Destroy()
	end)

	-- what an agent looks for before it invokes anything
	print(`[harness] server ok ({#commands + 1} commands, {bindable:GetFullName()})`)

	return self
end, function(self: HarnessService)
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	self._Bodies:Destroy()
	table.clear(self :: any)
end)
