--!strict
-- Services
-- Packages
-- Modules
-- Types
-- an end of a ride the way a map marks it: a pad or an exit, + the id the two of a pair share
export type End<P> = {
	Part: P,
	Id: string,
}
-- which exit every pad leads to, + what the marks of the map have wrong with them
export type Pairing<P> = {
	Exits: { [P]: P },
	-- a pad that leads nowhere or to two places at once: it's spelt wrong + carries nobody
	Faults: { string },
	-- an exit nobody is led to: odd, nothing more
	Notes: { string },
}
export type Facing = "Exit" | "Center"
-- what setting somebody down reads of the rule of a game
export type Landing = {
	Rise: { Min: number, Max: number },
	Spread: number,
	Facing: Facing,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the part of a ride that asks nothing of the engine: which pad leads where, who a pad carries + where it sets them
-- down
local Util = {}

-- a pair is a pad + the exit of the same id. two pads may lead to one exit, one pad never leads to two
function Util.pair<P>(pads: { End<P> }, exits: { End<P> }): Pairing<P>
	local exitParts: { [string]: P } = {}
	local isDoubled: { [string]: true } = {}
	local isLedTo: { [string]: true } = {}
	local pairing: Pairing<P> = {
		Exits = {},
		Faults = {},
		Notes = {},
	}
	for _, exit in exits do
		if exitParts[exit.Id] == nil then
			exitParts[exit.Id] = exit.Part
		elseif not isDoubled[exit.Id] then
			isDoubled[exit.Id] = true
			table.insert(pairing.Faults, `two exits are marked "{exit.Id}"`)
		end
	end
	for _, pad in pads do
		isLedTo[pad.Id] = true
		local exitPart = exitParts[pad.Id]
		if exitPart == nil then
			table.insert(pairing.Faults, `the pad "{pad.Id}" has no exit`)
		elseif not isDoubled[pad.Id] then
			pairing.Exits[pad.Part] = exitPart
		end
	end
	for _, exit in exits do
		if not isLedTo[exit.Id] then
			isLedTo[exit.Id] = true
			table.insert(pairing.Notes, `no pad leads to the exit "{exit.Id}"`)
		end
	end
	return pairing
end

-- both waits are over. one that was never started is
function Util.getIfReady(now: number, padReadyAt: number?, riderReadyAt: number?): boolean
	return now >= (padReadyAt or -math.huge) and now >= (riderReadyAt or -math.huge)
end

-- where somebody who rides to the exit is set down, by their pivot
function Util.getLanding(exit: CFrame, landing: Landing, random: Random): CFrame
	local spread = landing.Spread
	local offset = Vector3.new(
		random:NextInteger(-spread, spread),
		random:NextInteger(landing.Rise.Min, landing.Rise.Max),
		random:NextInteger(-spread, spread)
	)
	if landing.Facing == "Exit" then
		return exit + offset
	end
	local position = exit.Position + offset
	-- right on the line there's no way to turn to it
	if position.X == 0 and position.Z == 0 then
		return CFrame.new(position)
	end
	return CFrame.lookAt(position, Vector3.new(0, position.Y, 0))
end

return Util
