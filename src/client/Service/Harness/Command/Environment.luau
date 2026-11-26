--!strict
-- Services
-- Packages
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local EnvironmentService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Environment")
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
-- Types
local EnvironmentType = require("@game/ReplicatedStorage/Shared/Type/Environment")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Command = Harness.Command
-- Constants
local GRADE = Harness.newArgument(
	"Grade",
	"string",
	EnvironmentType.Grade,
	"the look the screen is graded to: normal, comic, dark, dreary, greenlit or noir"
)
local OVERRIDE = Harness.newArgument(
	"Override",
	"table",
	EnvironmentType.Override,
	'what this screen shows whatever the server says: { Season = "winter", Weather = "blizzard", Time = "night" }, any of the three'
)
-- Variables
-- References
-- Private Functions
local function getState(): { [string]: any }
	assert(EnvironmentService.IsInitialized, `the environment service isn't initialized`)
	return {
		Season = EnvironmentService:GetSeason(),
		Weather = EnvironmentService:GetWeather(),
		IsNight = EnvironmentService:GetIfNight(),
		ClockTime = EnvironmentService:GetClockTime(),
		Grade = EnvironmentService:GetGrade(),
		Override = EnvironmentService:GetOverride(),
	}
end
-- Class
local Module = {}

Module.list = function(): { Command }
	return {
		Harness.newCommand(
			"environment.get",
			"what this screen shows of the day: season, weather, the hour, the grade + the override that's on",
			{},
			function(): Result<any, string>
				return Result.ok(getState())
			end
		),
		Harness.newCommand(
			"environment.grade",
			"grades this screen, the way the roleplay bar's pick does",
			{ GRADE },
			function(args: { [string]: any }): Result<any, string>
				assert(EnvironmentService.IsInitialized, `the environment service isn't initialized`)
				EnvironmentService:SetGrade(args.Grade)
				return Result.ok(getState())
			end
		),
		Harness.newCommand(
			"environment.override",
			"has this screen show a season, a weather or a time of its own, merged into the override that's on",
			{ OVERRIDE },
			function(args: { [string]: any }): Result<any, string>
				assert(EnvironmentService.IsInitialized, `the environment service isn't initialized`)
				EnvironmentService:SetOverride(args.Override)
				return Result.ok(getState())
			end
		),
		Harness.newCommand(
			"environment.clear",
			"drops the override of this screen: it follows the server again",
			{},
			function(): Result<any, string>
				assert(EnvironmentService.IsInitialized, `the environment service isn't initialized`)
				EnvironmentService:ClearOverride()
				return Result.ok(getState())
			end
		),
	}
end

return Module
