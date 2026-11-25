--!strict
-- Services
-- Packages
-- Modules
local AcrobaticsDefinition = require("@game/ReplicatedStorage/Shared/Definition/Acrobatics")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type Properties = ClientVFXType.Tumble
-- what a move comes to, step by step, before anything is moved by it
export type Plan = {
	-- studs a second the body is carried upwards at in each step of its throw, it's let go of after the last
	Lift: { number },
	-- how far the body is turned from how it stood in each step of the move. false: it's left the way it is
	Turn: { CFrame | false },
}
-- Constants
local STEP = AcrobaticsDefinition.STEP
local LIFT_DIVISOR = AcrobaticsDefinition.LIFT_DIVISOR
local LIFT_DECAY = AcrobaticsDefinition.LIFT_DECAY
-- a pause of a whole number of steps isn't a step longer for what's lost dividing it
local EPSILON = 1e-6
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.get = function(props: Properties): Plan
	-- the throw is slowed before its first step, so it never carries the body at the speed it's named by
	local lift: { number } = {}
	for step = 1, props.Up // LIFT_DIVISOR do
		lift[step] = props.Up - LIFT_DECAY * step
	end
	local turn: { CFrame | false } = {}
	local target = CFrame.identity
	for _, phase in props.Phases do
		if phase.Type == "Turn" then
			local rotation = CFrame.fromEulerAnglesXYZ(phase.Angles.X, phase.Angles.Y, phase.Angles.Z)
			for _ = 1, phase.Count do
				target *= rotation
				-- a move that turns nothing still takes the steps its turn would have
				table.insert(turn, if props.IsTurned then target else false)
			end
		else
			-- the old scheduler woke a wait with the first of its steps that was late enough
			for _ = 1, math.ceil(phase.Duration / STEP - EPSILON) do
				table.insert(turn, false)
			end
		end
	end
	return table.freeze({
		Lift = table.freeze(lift),
		Turn = table.freeze(turn),
	})
end

return Module
