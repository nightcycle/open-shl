--!strict
-- Services
local Lighting = game:GetService("Lighting")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
-- Modules
local DayNightDefinition = require("@game/ServerScriptService/Server/Definition/DayNight")
local MapDefinition = require("@game/ServerScriptService/Server/Definition/Map")
-- Types
type DayNightServiceImpl = {
	__index: DayNightServiceImpl,
}
export type DayNightService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		_Lamps: { BasePart },
		_Windows: { Model },
		_WindowThreads: { thread }, -- one per building that's still switching
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: DayNightServiceImpl
))
-- Constants
-- Variables
-- References
-- Private Functions
local function setLamps(lamps: { BasePart }, isLit: boolean)
	local look = if isLit then DayNightDefinition.LAMP_LOOKS.Lit else DayNightDefinition.LAMP_LOOKS.Unlit
	for _, lamp in lamps do
		lamp.Material = look.Material
		lamp.Transparency = look.Transparency
		lamp.BrickColor = look.BrickColor
		local light = lamp:FindFirstChildWhichIsA("Light")
		if light then
			light.Enabled = isLit
		end
	end
end

-- a pane that's on its own is a room, the panes of a model are the windows of one room + light up together
local function getPanes(room: Instance): { BasePart }
	local panes: { BasePart } = {}
	if room:IsA("BasePart") then
		table.insert(panes, room)
	elseif room:IsA("Model") then
		for _, pane in room:GetChildren() do
			if pane:IsA("BasePart") then
				table.insert(panes, pane)
			end
		end
	end
	return panes
end

local function getPalette(windows: Model): { BrickColor }
	local palette: { BrickColor } = {}
	for _, child in windows:GetChildren() do
		if not child:IsA("Folder") then
			continue
		end
		for _, color in child:GetChildren() do
			if color:IsA("BrickColorValue") then
				table.insert(palette, color.Value)
			end
		end
	end
	return palette
end

local function getLitTransparency(rng: Random): number
	local tenths = DayNightDefinition.LIT_WINDOW_TENTHS
	return rng:NextInteger(tenths.Min, tenths.Max) / 10
end

-- every room picks its color the moment the night falls. a pane that's on its own is lit right then as well, the
-- rooms of several stay dark until it's their turn
local function colorWindows(windows: Model, rng: Random)
	local palette = getPalette(windows)
	if #palette == 0 then
		return
	end
	for _, room in windows:GetChildren() do
		local panes = getPanes(room)
		if #panes == 0 then
			continue
		end
		local color = palette[rng:NextInteger(1, #palette)]
		for _, pane in panes do
			pane.BrickColor = color
		end
		if room:IsA("BasePart") then
			room.Transparency = getLitTransparency(rng)
		end
	end
end

-- yields. a building doesn't switch all at once, its rooms follow one another until the last one is done
local function switchWindows(windows: Model, isLit: boolean)
	local rng = Random.new()
	if isLit then
		colorWindows(windows, rng)
	end
	-- the palette sits among the rooms + takes a turn like one, it's what the pace of a building is counted by
	local rooms = windows:GetChildren()
	for _, room in rooms do
		task.wait(DayNightDefinition.WINDOW_SWITCH_DURATION / #rooms)
		local transparency = if isLit then getLitTransparency(rng) else 1
		for _, pane in getPanes(room) do
			pane.Transparency = transparency
		end
	end
end

-- a building that's done switching left a thread behind that's dead, there's nothing of it to cancel
local function cancelWindows(self: DayNightService)
	for _, thread in self._WindowThreads do
		if coroutine.status(thread) == "suspended" then
			task.cancel(thread)
		end
	end
	table.clear(self._WindowThreads)
end

local function switchAllWindows(self: DayNightService, isLit: boolean)
	-- a switch that's still going would undo this one room by room
	cancelWindows(self)
	for _, windows in self._Windows do
		table.insert(self._WindowThreads, task.spawn(switchWindows, windows, isLit))
	end
end

-- yields for as long as the service lives
local function run(self: DayNightService)
	local clockTick = DayNightDefinition.START_TICK
	local isNight = DayNightDefinition.getIfNight(clockTick)
	setLamps(self._Lamps, isNight)
	while true do
		if DayNightDefinition.getIfNight(clockTick) ~= isNight then
			isNight = not isNight
			setLamps(self._Lamps, isNight)
			switchAllWindows(self, isNight)
		end
		-- the lighting replicates, so every client sees the sun where the server has it
		local clockTime = DayNightDefinition.getClockTime(clockTick)
		Lighting.ClockTime = clockTime
		local brightness = DayNightDefinition.getBrightness(clockTime)
		if brightness then
			Lighting.Brightness = brightness
		end
		task.wait(DayNightDefinition.getTickDuration(isNight))
		clockTick = DayNightDefinition.getNextTick(clockTick)
	end
end
-- Class
local DayNightService = {} :: DayNightServiceImpl
DayNightService.__index = DayNightService

return ServiceLocker(function(): DayNightService
	local self = setmetatable({
		IsInitialized = true :: true,
		_Lamps = MapDefinition.list(MapDefinition.StreetLamp),
		_Windows = MapDefinition.list(MapDefinition.NightWindows),
		_WindowThreads = {},
		_CleanUpCallbacks = {},
		_Connections = {},
	}, DayNightService)

	local clockThread = task.spawn(run, self)
	table.insert(self._CleanUpCallbacks, function()
		task.cancel(clockThread)
		cancelWindows(self)
	end)

	return self
end, function(self: DayNightService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
