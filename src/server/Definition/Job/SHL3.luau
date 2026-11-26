--!strict
-- Services
-- Packages
-- Modules
-- Types
local JobType = require("@game/ServerScriptService/Server/Type/Job")
local SharedJobType = require("@game/ReplicatedStorage/Shared/Type/Job")
type End = JobType.End
type Rule = JobType.Rule
type Stat = SharedJobType.Stat
-- Constants
-- Variables
-- References
-- Private Functions
local function newEnd(stat: Stat, isHigh: boolean, text: string): End
	return table.freeze({
		Stat = stat,
		IsHigh = isHigh,
		Text = text,
	})
end
-- Class
-- in the order the old place asked them in: whoever is out at two ends at once reads the first
local ENDS: { End } = table.freeze({
	newEnd(
		"Morality",
		false,
		"Nobody wants to work with a villain. You are forced to retire for your disturbing lack of a moral compass."
	),
	newEnd(
		"Morality",
		true,
		"Your boss worries that you'll report them for shady decisions in the past due to how morally righteous you are. You are forced to retire."
	),
	newEnd(
		"Colleagues",
		false,
		"You are so unlikable that your boss has no choice but to force you to retire to prevent a company wide mutiny."
	),
	newEnd(
		"Colleagues",
		true,
		"You're too popular. Your boss is annoyed that you're more influential than they are, you are forced to retire."
	),
	newEnd("Accomplishments", false, "You get nothing done. You are forced to retire for incompetence."),
	newEnd(
		"Accomplishments",
		true,
		"You're so good at your job you make everyone else look bad. You're forced to retire so that nobody else has to compete with your insane standard."
	),
	newEnd(
		"Happiness",
		false,
		"You are so unhappy you stop getting out of bed to go to work. You are forced to retire soon after for this."
	),
	newEnd(
		"Happiness",
		true,
		"You are so happy in your job that you're creeping people out. You are forced to retire for the sake of the company."
	),
})
-- its old place had the client keep all of this + tell the server what it had earned. the numbers are that client's:
-- the four were declared at 7 + set to 8 before a shift was ever shown. an answer pays 25 + two hundredths of that
-- more for every answer so far, up to 43.75 from the 38th on, + there's one every 3.5 seconds: about 750 a minute for
-- as long as the four are kept off both ends, against an allowance of 10. an outlier, kept. whoever a pad took on is
-- taken on again once they were seen 30 studs from it, which is looked at once a minute + whenever it's stepped on
local RULE: Rule = table.freeze({
	StartStat = 8,
	MaxStat = 16,
	BasePay = 25,
	RaisePerAnswer = 0.02,
	MaxRaise = 1.75,
	ReadDuration = 3.5,
	Radius = 30,
	AuditInterval = 60,
	Ends = ENDS,
	EndSuffix = " Please wait to reapply.",
})

return RULE
