--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local Types = {}

local isHour = Type.numberConstrained(0, 24)
local isCount = Type.intersection(Type.integer, Type.numberMin(0))

-- they go by what the lighting of their place calls them
export type Season = "summer" | "autumn" | "winter" | "spring"
Types.Season = Type.literal("summer", "autumn", "winter", "spring")

-- what a day may be rolled as
export type Weather = "sunny" | "rain" | "rainstorm" | "snow" | "blizzard" | "thunder" | "thunderstorm" | "cloudy" | "fog"
Types.Weather =
	Type.literal("sunny", "rain", "rainstorm", "snow", "blizzard", "thunder", "thunderstorm", "cloudy", "fog")

-- a way the colors of the whole picture are bent, a player picks one for their own screen
export type Grade = "normal" | "comic" | "dark" | "dreary" | "greenlit" | "noir"
Types.Grade = Type.literal("normal", "comic", "dark", "dreary", "greenlit", "noir")

export type Precipitation = "rain" | "snow"
Types.Precipitation = Type.literal("rain", "snow")

-- an hour a player may hold their own sky at
export type TimeOfDay = "day" | "dusk" | "night" | "dawn"
Types.TimeOfDay = Type.literal("day", "dusk", "night", "dawn")

-- what a weather comes to on a screen
export type WeatherLook = {
	Sky: string, -- the name of a sky in the lighting of the place
	IsSunny: boolean, -- the sun, the moon + the rays of the sun are out
	Precipitation: Precipitation?,
	IsFoggy: boolean,
	HasLightning: boolean, -- nothing is drawn for it so far
}
Types.WeatherLook = Type.strictInterface({
	Sky = Type.string,
	IsSunny = Type.boolean,
	Precipitation = Type.optional(Types.Precipitation),
	IsFoggy = Type.boolean,
	HasLightning = Type.boolean,
})

-- what a season makes of the map
export type SeasonLook = {
	GroundColor: Color3,
	GroundMaterial: Enum.Material,
	WaterColor: Color3,
	IsFrozen: boolean, -- the pond can be walked on + no fountain runs
	LeafColors: { Color3 }, -- every leaf picks one, a color that's in twice is picked twice as often
	LeafTransparency: number,
}
Types.SeasonLook = Type.strictInterface({
	GroundColor = Type.Color3,
	GroundMaterial = Type.enum(Enum.Material),
	WaterColor = Type.Color3,
	IsFrozen = Type.boolean,
	LeafColors = Type.array(Type.Color3),
	LeafTransparency = Type.numberConstrained(0, 1),
})

-- how many of the tickets a roll is drawn from are a weather's
export type Odds = {
	Weather: Weather,
	Tickets: number,
}
Types.Odds = Type.strictInterface({
	Weather = Types.Weather,
	Tickets = isCount,
})

-- what a player has their own screen show in place of what the server says. whatever is left out stays as it was
-- drawn when the first of them was set
export type Override = {
	Season: Season?,
	Weather: Weather?,
	Time: TimeOfDay?,
}
Types.Override = Type.strictInterface({
	Season = Type.optional(Types.Season),
	Weather = Type.optional(Types.Weather),
	Time = Type.optional(Types.TimeOfDay),
})

-- the day, the year + the weather of a game, + how each of them is drawn
export type Climate = {
	HourDuration: number, -- seconds an hour on the clock takes, by day + by night
	StartHour: number, -- what the clock reads as a server starts
	Dawn: number, -- the hour the windows of the city go dark at
	Dusk: number, -- + the one they light up at
	Seasons: { Season }, -- in the order of the year, a server starts in the first
	StartWeather: Weather,
	RollsPerSeason: number, -- the weather is rolled once a day, a season is over with the last of its rolls
	FirstRollHour: number, -- when the first day of a server is rolled, it's the only roll of that day
	RollHour: number, -- when every day after it is
	Odds: { [Season]: { Odds } },
	WeatherLooks: { [Weather]: WeatherLook },
	SeasonLooks: { [Season]: SeasonLook },
	TimeHours: { [TimeOfDay]: number }, -- the hour a sky that's held shows
	FogEnd: { Clear: number, Foggy: number }, -- studs
	ChangeDuration: number, -- seconds the fog, the ground + the water take to turn
	LeafDuration: number, -- seconds a leaf takes
	LeafDelay: NumberRange, -- seconds a leaf waits before it starts, so a tree doesn't turn all at once
	LeafMaterial: Enum.Material, -- the parts of a tree that are of it are its leaves
	IceMaterial: Enum.Material,
	ColorSteps: number, -- a color isn't eased into, it gets there in this many jumps
	Windows: {
		Transparency: NumberRange, -- how much of the room behind it a lit window lets through
		Range: number, -- studs the light of a pane that lets nothing through reaches
		OnDelay: number, -- seconds between two buildings as they light up
		OffDelay: number, -- + as they go dark
	},
	Precipitation: {
		Height: number, -- studs above the avatar it falls from
		BlockSize: Vector3,
		RoofReach: number, -- studs a roof is looked for above the avatar
		RoofDistance: number, -- one that's further off than this keeps nothing dry
		RoofOffsets: { Vector3 }, -- from the avatar: it's dry where there's a roof over every one of them
		LockSpeed: number, -- studs a second, an avatar that's faster takes what falls along
		SwapGap: number, -- seconds nothing falls for as one kind is swapped for the other
	},
	Spouts: { number }, -- seconds a spout runs for, is dry for, runs for.. over + over, from the start of the clock
}
Types.Climate = Type.strictInterface({
	HourDuration = Type.numberPositive,
	StartHour = isHour,
	Dawn = isHour,
	Dusk = isHour,
	Seasons = Type.array(Types.Season),
	StartWeather = Types.Weather,
	RollsPerSeason = Type.intersection(Type.integer, Type.numberMin(1)),
	FirstRollHour = isHour,
	RollHour = isHour,
	Odds = Type.map(Types.Season, Type.array(Types.Odds)),
	WeatherLooks = Type.map(Types.Weather, Types.WeatherLook),
	SeasonLooks = Type.map(Types.Season, Types.SeasonLook),
	TimeHours = Type.map(Types.TimeOfDay, isHour),
	FogEnd = Type.strictInterface({
		Clear = Type.numberPositive,
		Foggy = Type.numberPositive,
	}),
	ChangeDuration = Type.numberMin(0),
	LeafDuration = Type.numberMin(0),
	LeafDelay = Type.NumberRange,
	LeafMaterial = Type.enum(Enum.Material),
	IceMaterial = Type.enum(Enum.Material),
	ColorSteps = Type.intersection(Type.integer, Type.numberMin(1)),
	Windows = Type.strictInterface({
		Transparency = Type.NumberRange,
		Range = Type.numberMin(0),
		OnDelay = Type.numberMin(0),
		OffDelay = Type.numberMin(0),
	}),
	Precipitation = Type.strictInterface({
		Height = Type.number,
		BlockSize = Type.Vector3,
		RoofReach = Type.numberPositive,
		RoofDistance = Type.numberPositive,
		RoofOffsets = Type.array(Type.Vector3),
		LockSpeed = Type.numberMin(0),
		SwapGap = Type.numberMin(0),
	}),
	Spouts = Type.array(Type.numberPositive),
})

return Types
