--!strict
-- Services
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
-- Modules
local NetworkService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Network")
local RemoteDefinition = require("@game/ReplicatedStorage/Shared/Definition/Remote")
local ShellService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell")
-- Types
local JobType = require("@game/ReplicatedStorage/Shared/Type/Job")
local ShellType = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell/Types")
type Signal<T...> = Signal.Signal<T...>
export type JobShift = JobType.JobShift
type Screen = ShellType.Screen
type ScreenType = ShellType.ScreenType
type JobServiceImpl = {
	__index: JobServiceImpl,
	GetShift: (self: JobService) -> JobShift?,
	Answer: (self: JobService, isYes: boolean) -> (),
	Retire: (self: JobService) -> (),
}
export type JobService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		Changed: Signal<JobShift?>,
		-- the last the server said of the shift, nil while there's none
		_Shift: JobShift?,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: JobServiceImpl
))
-- Constants
-- the screen a shift is drawn on, up for as long as there's one
local SCREEN: Screen = table.freeze({
	Type = "JobMenu" :: "JobMenu",
})
local SCREEN_TYPE: ScreenType = SCREEN.Type
-- Variables
-- References
-- Private Functions
local function setShift(self: JobService, shift: JobShift?)
	if self._Shift == shift then
		return
	end
	self._Shift = shift
	self.Changed:Fire(shift)
end

-- the server is told the shift is over + this client doesn't wait to hear so
local function leave(self: JobService)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	if self._Shift == nil then
		return
	end
	setShift(self, nil)
	NetworkService:Fire(RemoteDefinition.RetireJob, nil)
end

local function onChanged(self: JobService, shift: JobShift?)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local screenType = ShellService:GetScreen().Type
	if shift == nil then
		setShift(self, nil)
		if screenType == SCREEN_TYPE then
			ShellService:CloseScreen()
		end
		return
	end
	-- taken on while another screen is up: there's nowhere to draw the job, so it's handed back
	if screenType ~= SCREEN_TYPE and screenType ~= "None" then
		setShift(self, nil)
		NetworkService:Fire(RemoteDefinition.RetireJob, nil)
		return
	end
	-- whoever draws the screen finds the shift there as it opens
	setShift(self, shift)
	-- the same goes for a job that came before the game was up
	if screenType == "None" and ShellService:OpenScreen(SCREEN).IsErr then
		leave(self)
	end
end
-- Class
local JobService = {} :: JobServiceImpl
JobService.__index = JobService

function JobService:GetShift(): JobShift?
	return self._Shift
end

-- a yes or a no to the card that's up. whether it's taken is the server's to say: the shift it sends next is the answer
function JobService:Answer(isYes: boolean)
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	local shift = self._Shift
	if shift == nil or shift.IsOver then
		return
	end
	NetworkService:Fire(RemoteDefinition.AnswerJob, isYes)
end

function JobService:Retire()
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	if self._Shift == nil then
		return
	end
	leave(self)
	if ShellService:GetScreen().Type == SCREEN_TYPE then
		ShellService:CloseScreen()
	end
end

-- the shift of this player as the server deals it: a pad of the map starts one, this client only ever answers or
-- leaves. the screen of the job comes + goes with the shift, so the shell has the avatar stand still + sheltered for
-- as long as it's on, the way it does for every screen
return ServiceLocker(function(): JobService
	assert(NetworkService.IsInitialized, `the network service isn't initialized`)
	assert(ShellService.IsInitialized, `the shell service isn't initialized`)
	local self = setmetatable({
		IsInitialized = true :: true,
		Changed = Signal.new(),
		_Shift = nil :: JobShift?,
		_CleanUpCallbacks = {},
		_Connections = {},
	}, JobService)

	table.insert(
		self._Connections,
		NetworkService:Connect(RemoteDefinition.JobChanged, function(shift: JobShift?)
			onChanged(self, shift)
		end)
	)
	-- the shell took the screen away under the shift: the server didn't count the avatar as in a menu, it's in a fight
	-- this client hadn't heard of. the two never disagree about a shift for longer than it takes to say so
	local screenConnection = ShellService.ScreenChanged:Connect(function(screen: Screen)
		if screen.Type ~= SCREEN_TYPE then
			leave(self)
		end
	end)
	table.insert(self._CleanUpCallbacks, function()
		screenConnection:Disconnect()
	end)

	return self
end, function(self: JobService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	self.Changed:Destroy()
	table.clear(self :: any)
end)
