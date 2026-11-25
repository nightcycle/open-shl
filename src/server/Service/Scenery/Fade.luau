--!strict
-- Services
-- Packages
-- Modules
-- Types
-- a write of how see-through a door is, + the seconds since the one before it
export type Step = {
	Delay: number,
	Transparency: number,
}
-- Constants
-- writes either way: the old door went up a tenth at a time, the last of them to where it stays
local STEP_COUNT = 8
-- Variables
-- References
-- Private Functions
-- Class
-- how a door that's clicked fades out of the way + back, as the stepped writes its old place made: no tween
local Util = {}

-- from shut to open over the fade, open for as long as it stays, + back the same way. the first is written at once
function Util.getSteps(
	shutTransparency: number,
	openTransparency: number,
	fadeDuration: number,
	openDuration: number
): { Step }
	local steps: { Step } = {}
	local stepDuration = fadeDuration / (STEP_COUNT - 1)
	for index = 1, STEP_COUNT do
		table.insert(steps, {
			Delay = if index == 1 then 0 else stepDuration,
			Transparency = if index == STEP_COUNT
				then openTransparency
				else shutTransparency + (openTransparency - shutTransparency) * index / STEP_COUNT,
		})
	end
	for index = 1, STEP_COUNT do
		table.insert(steps, {
			Delay = if index == 1 then openDuration else stepDuration,
			Transparency = if index == STEP_COUNT
				then shutTransparency
				else openTransparency + (shutTransparency - openTransparency) * index / STEP_COUNT,
		})
	end
	return steps
end

return Util
