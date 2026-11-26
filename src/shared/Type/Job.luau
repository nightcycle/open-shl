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

-- a job somebody is taken on for: the name the pad of the map carries
export type JobId = "Teacher" | "Doctor" | "Mentor" | "Businessperson"
Types.JobId = Type.literal("Teacher", "Doctor", "Mentor", "Businessperson")

-- one of the four things a shift is judged by
export type Stat = "Morality" | "Colleagues" | "Accomplishments" | "Happiness"
Types.Stat = Type.literal("Morality", "Colleagues", "Accomplishments", "Happiness")

-- what a client is told of its shift. what an answer does to the four is never sent: a card can't be read off the wire
export type JobShift = {
	JobId: JobId,
	-- the card that's asked, or the line the job ended on
	Text: string,
	Morality: number,
	Colleagues: number,
	Accomplishments: number,
	Happiness: number,
	-- what's handed over when the shift ends
	Paycheck: number,
	-- when the next answer is taken, on the clock every client shares with the server
	ReadyAt: number,
	-- nothing is left to answer, only to leave
	IsOver: boolean,
}
do -- Types.JobShift
	-- a shift ends at either end of it, so nothing past them is ever sent
	local isStat = Type.intersection(Type.integer, Type.numberConstrained(0, 16))
	Types.JobShift = Type.strictInterface({
		JobId = Types.JobId,
		Text = Type.string,
		Morality = isStat,
		Colleagues = isStat,
		Accomplishments = isStat,
		Happiness = isStat,
		Paycheck = Type.intersection(Type.integer, Type.numberMin(0)),
		ReadyAt = Type.number,
		IsOver = Type.boolean,
	})
end

return Types
