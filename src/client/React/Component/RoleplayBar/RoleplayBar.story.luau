--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
local EnvironmentType = require("@game/ReplicatedStorage/Shared/Type/Environment")
type Season = EnvironmentType.Season
type Weather = EnvironmentType.Weather
type TimeOfDay = EnvironmentType.TimeOfDay
type Grade = EnvironmentType.Grade
type EmoteInfo = ParentComponent.EmoteInfo
-- Constants
-- the buttons of the old place, in its order. the first three are held until they're pressed again
local EMOTES: { EmoteInfo } = table.freeze({
	table.freeze({ Id = "AtEase", Name = "At Ease" } :: EmoteInfo),
	table.freeze({ Id = "HeroicPose", Name = "Heroic Pose" } :: EmoteInfo),
	table.freeze({ Id = "Kneel", Name = "Kneel" } :: EmoteInfo),
	table.freeze({ Id = "Dab", Name = "Dab" } :: EmoteInfo),
	table.freeze({ Id = "Laugh", Name = "Laugh" } :: EmoteInfo),
})
local HELD_IDS: { [string]: true } = table.freeze({
	AtEase = true :: true,
	HeroicPose = true :: true,
	Kneel = true :: true,
})
-- what each button of the upper row goes through, in the order the old place had them in
local SEASONS: { Season } = table.freeze({ "summer" :: Season, "autumn", "winter", "spring" })
local TIMES: { TimeOfDay } = table.freeze({ "day" :: TimeOfDay, "dusk", "night", "dawn" })
local WEATHERS: { Weather } = table.freeze({
	"sunny" :: Weather,
	"rain",
	"rainstorm",
	"snow",
	"blizzard",
	"thunder",
	"thunderstorm",
	"cloudy",
	"fog",
})
local GRADES: { Grade } = table.freeze({ "comic" :: Grade, "dark", "dreary", "greenlit", "noir", "normal" })
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function getNext<V>(values: { V }, value: V): V
	local index = table.find(values, value) or 0
	return values[index % #values + 1]
end
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl3"),
		-- without it the whole upper row is one button, a press of it is printed
		IsOwned = UILabs.Boolean(true),
	},
}, function(props)
	-- stands in for the container: a pose is held until it's pressed again, each button of the upper row moves on
	local heldId: string?, setHeldId: (string?) -> () = React.useState(nil :: string?)
	local isFolded: boolean, setIsFolded: (boolean) -> () = React.useState(false)
	local season: Season, setSeason: (Season) -> () = React.useState("summer" :: Season)
	local time: TimeOfDay, setTime: (TimeOfDay) -> () = React.useState("day" :: TimeOfDay)
	local weather: Weather, setWeather: (Weather) -> () = React.useState("sunny" :: Weather)
	local grade: Grade, setGrade: (Grade) -> () = React.useState("normal" :: Grade)
	local areNamesHidden: boolean, setAreNamesHidden: (boolean) -> () = React.useState(false)
	local isHudHidden: boolean, setIsHudHidden: (boolean) -> () = React.useState(false)

	local emotes: { EmoteInfo } = {}
	for _, emote in EMOTES do
		table.insert(emotes, {
			Id = emote.Id,
			Name = emote.Name,
			IsDead = heldId ~= nil and heldId ~= emote.Id,
		})
	end

	return StyleStory.provide(props.controls.Style, {
		-- the strip was laid out for a screen that's wider than it's high
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			ClipsDescendants = true,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			Bar = e(
				ParentComponent,
				{
					Size = UDim2.fromScale(1, 1),
					Emotes = emotes,
					IsFolded = isFolded,
					IsOwned = props.controls.IsOwned,
					Season = season,
					Time = time,
					Weather = weather,
					Grade = grade,
					AreNamesHidden = areNamesHidden,
					IsHudHidden = isHudHidden,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "Emote" then
							if heldId == action.Id then
								setHeldId(nil)
							elseif HELD_IDS[action.Id] then
								setHeldId(action.Id)
							else
								print(`"{action.Id}" is played once`)
							end
						elseif action.Type == "Mask" then
							print("a hand goes to the mask")
						elseif action.Type == "Fold" then
							setIsFolded(not isFolded)
						elseif action.Type == "Buy" then
							print("the upper row is asked for")
						elseif action.Type == "Season" then
							setSeason(getNext(SEASONS, season) :: Season)
						elseif action.Type == "Time" then
							setTime(getNext(TIMES, time) :: TimeOfDay)
						elseif action.Type == "Weather" then
							setWeather(getNext(WEATHERS, weather) :: Weather)
						elseif action.Type == "Grade" then
							setGrade(getNext(GRADES, grade) :: Grade)
						elseif action.Type == "Names" then
							setAreNamesHidden(not areNamesHidden)
						elseif action.Type == "HideUi" then
							setIsHudHidden(true)
						elseif action.Type == "ShowUi" then
							setIsHudHidden(false)
						end
					end,
				} :: ParentComponent.Properties
			),
		}),
	})
end)
