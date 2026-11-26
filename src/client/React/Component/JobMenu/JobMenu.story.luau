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
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
-- Types
local JobType = require("@game/ReplicatedStorage/Shared/Type/Job")
type JobShift = JobType.JobShift
type Stat = JobType.Stat
-- a card of the stand-in server: what's asked + what a yes does to one of the four
type Card = {
	Text: string,
	Stat: Stat,
	Change: number,
}
-- Constants
-- a few of the cards of the old place, the longest of them among them. each moves one of the four here, so every end
-- is a few presses away
local CARDS: { Card } = table.freeze({
	table.freeze({
		Text = "You notice a kid bullying another kid. Do you stop the bully?",
		Stat = "Morality" :: Stat,
		Change = 2,
	}),
	table.freeze({
		Text = "You're bored, do you goof off with colleagues?",
		Stat = "Colleagues" :: Stat,
		Change = 2,
	}),
	table.freeze({
		Text = "You interview someone to hire. They were a villain in the past but claim to have changed. Do you hire them?",
		Stat = "Accomplishments" :: Stat,
		Change = -2,
	}),
	table.freeze({
		Text = "An underqualified friend is applying for a job at your work, they are asking you to put a good word in despite you knowing they shouldn't be hired.",
		Stat = "Happiness" :: Stat,
		Change = 2,
	}),
})
-- what a shift that ran out at an end reads, about as long as the longest of the old place
local END_TEXT =
	"You're so good at your job you make everyone else look bad. You're forced to retire so that nobody else has to compete with your insane standard. Please wait to reapply."
local STAT_START = 8
local STAT_MAX = 16
local BASE_PAY = 25
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function newShift(): JobShift
	return table.freeze({
		JobId = "Teacher" :: "Teacher",
		Text = CARDS[1].Text,
		Morality = STAT_START,
		Colleagues = STAT_START,
		Accomplishments = STAT_START,
		Happiness = STAT_START,
		Paycheck = 0,
		ReadyAt = 0,
		IsOver = false,
	})
end
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl3"),
		-- seconds a card is up for before the next answer is taken
		ReadDuration = UILabs.Slider(3.5, 0, 6, 0.5),
		IsTouch = UILabs.Boolean(false),
	},
}, function(props)
	-- stands in for the server: it deals the cards in turn, moves the four + counts the cheque
	local shift: JobShift, setShift: (JobShift) -> () = React.useState(newShift)
	local answerCount, setAnswerCount = React.useState(0)
	local isReading: true?, setIsReading: (true?) -> () = useTimedState(props.controls.ReadDuration)

	return StyleStory.provide(props.controls.Style, {
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			ClipsDescendants = true,
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(1, 1),
		}, {
			Menu = e(
				ParentComponent,
				{
					Size = UDim2.fromScale(1, 1),
					Shift = shift,
					IsReading = isReading == true,
					IsTouch = props.controls.IsTouch,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "Retire" then
							-- the next shift starts where the pad would start it
							setShift(newShift())
							setAnswerCount(0)
							setIsReading(nil)
							return
						end
						local card = CARDS[answerCount % #CARDS + 1]
						local nextCard = CARDS[(answerCount + 1) % #CARDS + 1]
						local out = table.clone(shift)
						local value = math.clamp(
							out[card.Stat] + (if action.IsYes then card.Change else -card.Change),
							0,
							STAT_MAX
						)
						out[card.Stat] = value
						out.Paycheck =
							math.floor(shift.Paycheck + BASE_PAY * math.min(1.75, 1 + 0.02 * (answerCount + 1)))
						out.IsOver = value <= 0 or value >= STAT_MAX
						out.Text = if out.IsOver then END_TEXT else nextCard.Text
						setShift(table.freeze(out))
						setAnswerCount(answerCount + 1)
						setIsReading(true)
					end,
				} :: ParentComponent.Properties
			),
		}),
	})
end)
