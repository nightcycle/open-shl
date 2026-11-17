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
local MINUTES_PER_HOUR = 60
local MINUTES_PER_DAY = 24 * MINUTES_PER_HOUR
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
local function getRooms(windows: Model): { { BasePart } }
	local rooms: { { BasePart } } = {}
	for _, child in windows:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(rooms, { child })
		elseif child:IsA("Model") then
			local panes: { BasePart } = {}
			for _, pane in child:GetChildren() do
				if pane:IsA("BasePart") then
					table.insert(panes, pane)
				end
			end
			table.insert(rooms, panes)
		end
	end
	return rooms
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

-- yields. a building doesn't switch all at once, its rooms follow one another until the last one is done
local function switchWindows(windows: Model, isLit: boolean)
	local rng = Random.new()
	local rooms = getRooms(windows)
	local palette = getPalette(windows)
	local range = DayNightDefinition.LIT_WINDOW_TRANSPARENCY
	for _, panes in rooms do
		task.wait(DayNightDefinition.WINDOW_SWITCH_DURATION / #rooms)
		local color = if isLit and #palette > 0 then palette[rng:NextInteger(1, #palette)] else nil
		local transparency = if isLit then rng:NextNumber(range.Min, range.Max) else 1
		for _, pane in panes do
			pane.Transparency = transparency
			if color then
				pane.BrickColor = color
			end
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
	local minute = DayNightDefinition.START_TIME * MINUTES_PER_HOUR
	local isNight = DayNightDefinition.getIfNight(minute / MINUTES_PER_HOUR)
	setLamps(self._Lamps, isNight)
	while true do
		local clockTime = minute / MINUTES_PER_HOUR
		if DayNightDefinition.getIfNight(clockTime) ~= isNight then
			isNight = not isNight
			setLamps(self._Lamps, isNight)
			switchAllWindows(self, isNight)
		end
		-- the lighting replicates, so every client sees the sun where the server has it
		Lighting.ClockTime = clockTime
		Lighting.Brightness = DayNightDefinition.getBrightness(clockTime)
		task.wait(DayNightDefinition.getMinuteDuration(isNight))
		minute = (minute + 1) % MINUTES_PER_DAY
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
