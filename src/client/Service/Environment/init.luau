--!strict
-- Services
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
-- Packages
local ServiceLocker = require("@game/ReplicatedStorage/Packages/ServiceLocker")
local Signal = require("@game/ReplicatedStorage/Packages/Signal")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local EnvironmentDefinition = require("@game/ReplicatedStorage/Shared/Definition/Environment")
local PrecipitationDrawer = require("@self/Precipitation")
local SeasonDrawer = require("@self/Season")
local SkyDrawer = require("@self/Sky")
local SpoutDrawer = require("@self/Spout")
local WindowsDrawer = require("@self/Windows")
-- Types
local EnvironmentType = require("@game/ReplicatedStorage/Shared/Type/Environment")
type Season = EnvironmentType.Season
type Weather = EnvironmentType.Weather
type Grade = EnvironmentType.Grade
type Override = EnvironmentType.Override
-- what stays on the screen while the player has a say of their own: all of it stands still, whatever of it they
-- didn't pick is where it was as they first did
type Held = {
	Season: Season,
	-- false while it's still the map as it was built
	IsSeasonDrawn: boolean,
	Weather: Weather,
	-- nil for as long as the server never said when its clock started
	ClockTime: number?,
}
type EnvironmentServiceImpl = {
	__index: EnvironmentServiceImpl,
	-- what this screen shows, which is the server's word unless the player holds something else. the hour is nil
	-- until the server said when its clock started
	GetClockTime: (self: EnvironmentService) -> number?,
	GetIfNight: (self: EnvironmentService) -> boolean,
	GetSeason: (self: EnvironmentService) -> Season,
	GetWeather: (self: EnvironmentService) -> Weather,
	-- has this screen alone show a season, a weather or a time of day of the player's choosing, + stand still at it:
	-- the clock stops + nothing the server says is drawn until it's cleared. whatever is left out stays as it is
	SetOverride: (self: EnvironmentService, override: Override) -> (),
	-- nil while the screen follows the server
	GetOverride: (self: EnvironmentService) -> Override?,
	ClearOverride: (self: EnvironmentService) -> (),
	-- bends the colors of this screen alone, the day goes on under it
	SetGrade: (self: EnvironmentService, grade: Grade) -> (),
	GetGrade: (self: EnvironmentService) -> Grade,
}
export type EnvironmentService = typeof(setmetatable(
	{} :: {
		IsInitialized: true,
		-- the season, the weather, the windows or the grade on this screen changed, whoever had them do
		Changed: Signal.Signal<>,
		OverrideChanged: Signal.Signal<>,
		_Override: Override?,
		_Held: Held?,
		_Grade: Grade,
		-- what's on the screen. nil for whatever was never drawn, + a season of "" is the map as it was built
		_DrawnSeason: string?,
		_DrawnWeather: Weather?,
		_IsNightDrawn: boolean?,
		_DrawThread: thread?,
		_Sky: SkyDrawer.Drawer,
		_Season: SeasonDrawer.Drawer,
		_Windows: WindowsDrawer.Drawer,
		_Precipitation: PrecipitationDrawer.Drawer,
		_Spout: SpoutDrawer.Drawer,
		_Connections: { RBXScriptConnection },
		_CleanUpCallbacks: { () -> () },
	},
	{} :: EnvironmentServiceImpl
))
-- Constants
local CLIMATE = EnvironmentDefinition.CLIMATE
-- what a season that isn't drawn is kept as
local AUTHORED_SEASON = ""
-- the grades of a place + the effect they're copied onto, by what its lighting calls them
local GRADES_NAME = "Atmospheres"
local GRADE_EFFECT_NAME = "ColorCorrection"
local START_GRADE: Grade = "normal"
-- Variables
-- References
-- Private Functions
-- a server that hasn't said is at the start of its year
local function getServerSeason(): Season
	local season: Season = AttributeDefinition.get(Workspace, AttributeDefinition.Season) or CLIMATE.Seasons[1]
	return season
end

local function getServerWeather(): Weather
	local weather: Weather = AttributeDefinition.get(Workspace, AttributeDefinition.Weather) or CLIMATE.StartWeather
	return weather
end

-- the first summer of a server is the map as it was built, a season only has a look of its own once one is over
local function getIfServerSeasonDrawn(): boolean
	return (AttributeDefinition.get(Workspace, AttributeDefinition.SeasonsPassed) or 0) > 0
end

local function getServerClockTime(): number?
	local startedAt = AttributeDefinition.get(Workspace, AttributeDefinition.ClockStartedAt)
	return if startedAt then EnvironmentDefinition.getClockTime(startedAt, Workspace:GetServerTimeNow()) else nil
end

local function getClockTime(self: EnvironmentService): number?
	local held = self._Held
	if held then
		return held.ClockTime
	end
	return getServerClockTime()
end

-- the sun is put where the hour has it on every frame, + the windows of the city follow the hour from the first one
-- on: a server that starts at midnight starts lit
local function drawClock(self: EnvironmentService, isRushed: boolean)
	local clockTime = getClockTime(self)
	if not clockTime then
		return
	end
	Lighting.ClockTime = clockTime
	local isNight = EnvironmentDefinition.getIfNight(clockTime)
	if isNight ~= self._IsNightDrawn then
		-- what was never drawn has nothing to switch from
		local isFirst = self._IsNightDrawn == nil
		self._IsNightDrawn = isNight
		self._Windows.Set(isNight, isRushed or isFirst)
		self.Changed:Fire()
	end
end

-- puts up whatever isn't on the screen yet. rushed is how somebody who just came in gets the day: as it is, with
-- nothing to watch turn
local function draw(self: EnvironmentService, isRushed: boolean)
	local held = self._Held
	-- written down with their types: the checker only knows one that comes out of an if for a string
	local season: Season = if held then held.Season else getServerSeason()
	local isSeasonDrawn = if held then held.IsSeasonDrawn else getIfServerSeasonDrawn()
	local weather: Weather = if held then held.Weather else getServerWeather()
	local isChanged = false

	local drawnSeason = if isSeasonDrawn then season else AUTHORED_SEASON
	if drawnSeason ~= self._DrawnSeason then
		-- a map nothing was drawn on is as it was built already
		local isUntouched = self._DrawnSeason == nil and not isSeasonDrawn
		self._DrawnSeason = drawnSeason
		if not isUntouched then
			self._Season.Set(if isSeasonDrawn then EnvironmentDefinition.getSeasonLook(season) else nil, isRushed)
		end
		isChanged = true
	end
	if weather ~= self._DrawnWeather then
		self._DrawnWeather = weather
		local look = EnvironmentDefinition.getWeatherLook(weather)
		self._Sky.Set(look, isRushed)
		self._Precipitation.Set(look.Precipitation)
		isChanged = true
	end
	if isChanged then
		self.Changed:Fire()
	end
	drawClock(self, isRushed)
end

-- a season + the count of them reach a client as two words, one draw has both
local function queueDraw(self: EnvironmentService)
	if self._DrawThread or self._Held then
		return
	end
	self._DrawThread = task.defer(function()
		self._DrawThread = nil
		if not self._Held then
			draw(self, false)
		end
	end)
end
-- Class
local EnvironmentService = {} :: EnvironmentServiceImpl
EnvironmentService.__index = EnvironmentService

function EnvironmentService:GetClockTime(): number?
	assert(self.IsInitialized, `the environment service isn't initialized`)
	return getClockTime(self)
end

function EnvironmentService:GetIfNight(): boolean
	assert(self.IsInitialized, `the environment service isn't initialized`)
	return self._IsNightDrawn == true
end

function EnvironmentService:GetSeason(): Season
	assert(self.IsInitialized, `the environment service isn't initialized`)
	local held = self._Held
	return if held then held.Season else getServerSeason()
end

function EnvironmentService:GetWeather(): Weather
	assert(self.IsInitialized, `the environment service isn't initialized`)
	local held = self._Held
	return if held then held.Weather else getServerWeather()
end

function EnvironmentService:SetOverride(override: Override)
	assert(self.IsInitialized, `the environment service isn't initialized`)
	assert(EnvironmentType.Override(override))
	local was = self._Override
	local held: Held = self._Held
		or {
			Season = getServerSeason(),
			IsSeasonDrawn = getIfServerSeasonDrawn(),
			Weather = getServerWeather(),
			ClockTime = getServerClockTime(),
		}
	local season: Season? = override.Season or (if was then was.Season else nil)
	local weather: Weather? = override.Weather or (if was then was.Weather else nil)
	local timeOfDay: EnvironmentType.TimeOfDay? = override.Time or (if was then was.Time else nil)
	self._Override = table.freeze({
		Season = season,
		Weather = weather,
		Time = timeOfDay,
	})
	self._Held = {
		Season = override.Season or held.Season,
		IsSeasonDrawn = override.Season ~= nil or held.IsSeasonDrawn,
		Weather = override.Weather or held.Weather,
		ClockTime = if override.Time then EnvironmentDefinition.getHour(override.Time) else held.ClockTime,
	}
	-- it's a jump, there's nothing in between to show
	draw(self, true)
	self.OverrideChanged:Fire()
end

function EnvironmentService:GetOverride(): Override?
	assert(self.IsInitialized, `the environment service isn't initialized`)
	return self._Override
end

function EnvironmentService:ClearOverride()
	assert(self.IsInitialized, `the environment service isn't initialized`)
	if not self._Held then
		return
	end
	self._Override = nil
	self._Held = nil
	draw(self, true)
	self.OverrideChanged:Fire()
end

function EnvironmentService:SetGrade(grade: Grade)
	assert(self.IsInitialized, `the environment service isn't initialized`)
	assert(EnvironmentType.Grade(grade))
	local grades = Lighting:FindFirstChild(GRADES_NAME)
	local source = grades and grades:FindFirstChild(grade)
	local effect = Lighting:FindFirstChild(GRADE_EFFECT_NAME)
	if
		not source
		or not source:IsA("ColorCorrectionEffect")
		or not effect
		or not effect:IsA("ColorCorrectionEffect")
	then
		warn(`the lighting has no grade "{grade}", or nothing to put one on`)
		return
	end
	effect.Brightness = source.Brightness
	effect.Contrast = source.Contrast
	effect.Saturation = source.Saturation
	effect.TintColor = source.TintColor
	self._Grade = grade
	self.Changed:Fire()
end

function EnvironmentService:GetGrade(): Grade
	assert(self.IsInitialized, `the environment service isn't initialized`)
	return self._Grade
end

-- the server says the season, the weather + when its clock started, this draws them: the sky, the fog, the ground,
-- the water, the trees, the fountains, the windows + what falls, all of it on this client alone. it sends nothing
return ServiceLocker(function(): EnvironmentService
	local self = setmetatable({
		IsInitialized = true :: true,
		Changed = Signal.new() :: Signal.Signal<>,
		OverrideChanged = Signal.new() :: Signal.Signal<>,
		_Override = nil :: Override?,
		_Held = nil :: Held?,
		_Grade = START_GRADE,
		_DrawnSeason = nil :: string?,
		_DrawnWeather = nil :: Weather?,
		_IsNightDrawn = nil :: boolean?,
		_DrawThread = nil :: thread?,
		_Sky = SkyDrawer.new(),
		_Season = SeasonDrawer.new(),
		_Windows = WindowsDrawer.new(),
		_Precipitation = PrecipitationDrawer.new(),
		_Spout = SpoutDrawer.new(),
		_CleanUpCallbacks = {},
		_Connections = {},
	}, EnvironmentService)

	-- whoever comes in late gets the day as it is, not the one the place was saved with until something changes
	draw(self, true)
	self._Spout.Set(AttributeDefinition.get(Workspace, AttributeDefinition.ClockStartedAt))

	local names = {
		AttributeDefinition.Season.Name,
		AttributeDefinition.SeasonsPassed.Name,
		AttributeDefinition.Weather.Name,
	}
	for _, name in names do
		table.insert(
			self._Connections,
			Workspace:GetAttributeChangedSignal(name):Connect(function()
				queueDraw(self)
			end)
		)
	end
	table.insert(
		self._Connections,
		Workspace:GetAttributeChangedSignal(AttributeDefinition.ClockStartedAt.Name):Connect(function()
			self._Spout.Set(AttributeDefinition.get(Workspace, AttributeDefinition.ClockStartedAt))
		end)
	)
	table.insert(
		self._Connections,
		RunService.RenderStepped:Connect(function()
			drawClock(self, false)
		end)
	)
	table.insert(self._CleanUpCallbacks, function()
		if self._DrawThread then
			task.cancel(self._DrawThread)
		end
		self._Sky.Destroy()
		self._Season.Destroy()
		self._Windows.Destroy()
		self._Precipitation.Destroy()
		self._Spout.Destroy()
	end)

	return self
end, function(self: EnvironmentService)
	for _, v in self._Connections do
		v:Disconnect()
	end
	for _, v in self._CleanUpCallbacks do
		task.spawn(v)
	end
	table.clear(self._CleanUpCallbacks)
	table.clear(self :: any)
end)
