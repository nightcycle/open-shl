--!strict
-- Services
-- Packages
-- Modules
-- Types
local EnvironmentType = require("@game/ReplicatedStorage/Shared/Type/Environment")
type Climate = EnvironmentType.Climate
-- Constants
-- the water of every season but the one it freezes in
local WATER_COLOR = Color3.fromRGB(49, 93, 151)
-- Variables
-- References
-- Private Functions
-- Class
-- the day of valor city, every number of it as its old place had it. a day is 8 minutes + a season is 3 of them
local Climate: Climate = {
	HourDuration = 20,
	StartHour = 0,
	Dawn = 7,
	Dusk = 18,
	Seasons = { "summer", "autumn", "winter", "spring" },
	StartWeather = "sunny",
	RollsPerSeason = 3,
	-- 20 seconds in, then not again until the afternoon of the day after: the first weather is the longest there is
	FirstRollHour = 1,
	RollHour = 13,
	-- it may snow in the summer, + only the cold half of the year has a ticket for fog
	Odds = {
		summer = {
			{ Weather = "sunny", Tickets = 15 },
			{ Weather = "rain", Tickets = 4 },
			{ Weather = "rainstorm", Tickets = 6 },
			{ Weather = "snow", Tickets = 2 },
			{ Weather = "blizzard", Tickets = 0 },
			{ Weather = "thunder", Tickets = 4 },
			{ Weather = "thunderstorm", Tickets = 5 },
			{ Weather = "cloudy", Tickets = 2 },
		},
		autumn = {
			{ Weather = "sunny", Tickets = 5 },
			{ Weather = "rain", Tickets = 2 },
			{ Weather = "rainstorm", Tickets = 3 },
			{ Weather = "snow", Tickets = 1 },
			{ Weather = "blizzard", Tickets = 0 },
			{ Weather = "thunder", Tickets = 3 },
			{ Weather = "thunderstorm", Tickets = 2 },
			{ Weather = "cloudy", Tickets = 6 },
			{ Weather = "fog", Tickets = 1 },
		},
		winter = {
			{ Weather = "sunny", Tickets = 5 },
			{ Weather = "rain", Tickets = 2 },
			{ Weather = "rainstorm", Tickets = 3 },
			{ Weather = "snow", Tickets = 9 },
			{ Weather = "blizzard", Tickets = 5 },
			{ Weather = "thunder", Tickets = 3 },
			{ Weather = "thunderstorm", Tickets = 2 },
			{ Weather = "cloudy", Tickets = 11 },
			{ Weather = "fog", Tickets = 5 },
		},
		spring = {
			{ Weather = "sunny", Tickets = 11 },
			{ Weather = "rain", Tickets = 8 },
			{ Weather = "rainstorm", Tickets = 6 },
			{ Weather = "snow", Tickets = 2 },
			{ Weather = "blizzard", Tickets = 0 },
			{ Weather = "thunder", Tickets = 4 },
			{ Weather = "thunderstorm", Tickets = 5 },
			{ Weather = "cloudy", Tickets = 2 },
		},
	},
	-- the sun is out under the clouds of a rain or a snow that's light, + it's gone under ones that drop nothing
	WeatherLooks = {
		sunny = { Sky = "sunny", IsSunny = true, IsFoggy = false, HasLightning = false },
		rain = { Sky = "cloudy", IsSunny = true, Precipitation = "rain", IsFoggy = false, HasLightning = false },
		rainstorm = { Sky = "storm", IsSunny = false, Precipitation = "rain", IsFoggy = true, HasLightning = false },
		snow = { Sky = "cloudy", IsSunny = true, Precipitation = "snow", IsFoggy = false, HasLightning = false },
		blizzard = { Sky = "storm", IsSunny = false, Precipitation = "snow", IsFoggy = true, HasLightning = false },
		thunder = { Sky = "storm", IsSunny = false, IsFoggy = false, HasLightning = true },
		thunderstorm = { Sky = "storm", IsSunny = false, Precipitation = "rain", IsFoggy = true, HasLightning = true },
		cloudy = { Sky = "cloudy", IsSunny = false, IsFoggy = false, HasLightning = false },
		fog = { Sky = "cloudy", IsSunny = false, IsFoggy = true, HasLightning = false },
	},
	SeasonLooks = {
		summer = {
			GroundColor = Color3.fromRGB(75, 151, 75),
			GroundMaterial = Enum.Material.Grass,
			WaterColor = WATER_COLOR,
			IsFrozen = false,
			LeafColors = { Color3.fromRGB(80, 109, 84), Color3.fromRGB(127, 142, 100) },
			LeafTransparency = 0,
		},
		-- two of its colors are in twice, a tree is more red + yellow than it's green or orange
		autumn = {
			GroundColor = Color3.fromRGB(100, 129, 69),
			GroundMaterial = Enum.Material.Grass,
			WaterColor = WATER_COLOR,
			IsFrozen = false,
			LeafColors = {
				Color3.fromRGB(80, 109, 84),
				Color3.fromRGB(136, 62, 62),
				Color3.fromRGB(136, 62, 62),
				Color3.fromRGB(218, 133, 65),
				Color3.fromRGB(239, 184, 56),
				Color3.fromRGB(239, 184, 56),
			},
			LeafTransparency = 0,
		},
		-- its trees are bare, the leaves are still there to bump into
		winter = {
			GroundColor = Color3.fromRGB(248, 248, 248),
			GroundMaterial = Enum.Material.Sand,
			WaterColor = Color3.fromRGB(21, 40, 66),
			IsFrozen = true,
			LeafColors = { Color3.fromRGB(44, 101, 29), Color3.fromRGB(31, 72, 20) },
			LeafTransparency = 1,
		},
		spring = {
			GroundColor = Color3.fromRGB(63, 126, 63),
			GroundMaterial = Enum.Material.Grass,
			WaterColor = WATER_COLOR,
			IsFrozen = false,
			LeafColors = { Color3.fromRGB(44, 101, 29), Color3.fromRGB(31, 72, 20) },
			LeafTransparency = 0,
		},
	},
	-- a dawn that's held is a little short of the hour the windows go dark at, so they're still lit
	TimeHours = {
		day = 12,
		dusk = 18,
		night = 0,
		dawn = 6.1,
	},
	-- the island is some 2,000 studs across: a fog hides the far shore, a clear day ends well behind it
	FogEnd = {
		Clear = 11000,
		Foggy = 2000,
	},
	ChangeDuration = 5,
	LeafDuration = 3,
	LeafDelay = NumberRange.new(1 / 12, 50 / 12),
	LeafMaterial = Enum.Material.Grass,
	IceMaterial = Enum.Material.Ice,
	ColorSteps = 20,
	Windows = {
		Transparency = NumberRange.new(0.15, 0.65),
		Range = 35,
		OnDelay = 0.09,
		OffDelay = 0.045,
	},
	Precipitation = {
		Height = 30,
		BlockSize = Vector3.new(75, 1, 75),
		RoofReach = 500,
		RoofDistance = 100,
		-- a little ahead of the avatar to either side, nothing looks behind it
		RoofOffsets = { Vector3.new(-5, 0, 1), Vector3.new(5, 0, 1) },
		LockSpeed = 40,
		SwapGap = 0.25,
	},
	Spouts = { 14, 9, 4, 11 },
}

return Climate
