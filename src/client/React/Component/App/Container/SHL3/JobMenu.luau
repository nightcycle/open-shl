--!strict
--!native
-- Services
local UserInputService = game:GetService("UserInputService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local JobService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Job")
-- Components
local JobMenu = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/JobMenu")
-- Hooks
local useSignalState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSignalState")
-- Contexts
-- Types
type JobShift = JobService.JobShift
export type Properties = {}
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the old place had this client deal its own cards, count its own cheque + tell the server what to pay. here it draws
-- the shift the server sends + says what was pressed: a yes, a no or the way out. the wait between two answers is
-- the server's as well, this only fades the buttons for as long as it says
return function(): React.ReactNode
	assert(JobService.IsInitialized, `the job service isn't initialized`)
	local shift: JobShift? = useSignalState(JobService.Changed, function(): JobShift?
		return JobService:GetShift()
	end)
	-- the shift whose wait is over. the clock it's told on is one this client keeps setting right, so the wait is
	-- counted down once + not read off it again
	local readShift: JobShift?, setReadShift: (JobShift?) -> () = React.useState(nil :: JobShift?)
	React.useEffect(function()
		if not shift then
			return function() end
		end
		local thread = task.delay(math.max(shift.ReadyAt - CombatDefinition.getTime(), 0), function()
			setReadShift(shift)
		end)
		return function()
			if coroutine.status(thread) == "suspended" then
				task.cancel(thread)
			end
		end
	end, { shift })

	-- the screen is taken away with the shift, there's nothing to draw of one that's gone
	if not shift then
		return nil
	end
	return e(
		JobMenu,
		{
			Size = UDim2.fromScale(1, 1),
			Shift = shift,
			IsReading = readShift ~= shift and shift.ReadyAt > CombatDefinition.getTime(),
			IsTouch = UserInputService.TouchEnabled,
			OnAction = function(action: JobMenu.ActionInfo)
				if action.Type == "Answer" then
					JobService:Answer(action.IsYes)
				elseif action.Type == "Retire" then
					JobService:Retire()
				end
			end,
		} :: JobMenu.Properties
	)
end
