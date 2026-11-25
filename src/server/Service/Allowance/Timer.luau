--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- a beat that runs until it's stopped. whoever starts one stops it: one that's left running goes on for as long as
-- the server does, which is what paid a player of the old place once more for every time they came back
local Util = {}

-- fn every interval seconds from now on, the first time an interval from now
function Util.start(interval: number, fn: () -> ()): thread
	return task.spawn(function()
		while true do
			task.wait(interval)
			fn()
		end
	end)
end

function Util.stop(thread: thread)
	-- one that's in the middle of its own beat can't be taken from under itself
	if coroutine.status(thread) == "suspended" then
		task.cancel(thread)
	end
end

return Util
