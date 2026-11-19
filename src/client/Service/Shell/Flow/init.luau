--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local ShellType = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Shell/Types")
export type Stop = ShellType.Stop
export type MenuAction = ShellType.MenuAction
export type Flow = ShellType.Flow
-- Constants
-- what a player goes through on the way in + where the buttons of the hud lead is the game's own, the flow of
-- another game is never required
local FLOW: Flow = GameDefinition.pick({
	shl1 = function(): Flow
		return require("@self/SHL1")
	end,
	shl2 = function(): Flow
		return require("@self/SHL2")
	end,
	shl3 = function(): Flow
		return require("@self/SHL3")
	end,
})
assert(ShellType.Flow(FLOW))
TableUtil.deepFreeze(FLOW)
-- Variables
-- References
-- Private Functions
-- Class
do
	-- the shell starts out in the first one, there's no game it could start out in before its session is in
	assert(FLOW.Stops[1] ~= nil, `the boot has no phase to start in`)
	-- the boot goes on from where a phase is on the list, so the second of a pair would lead back to the first
	local stops: { [string]: true } = {}
	for _, stop in FLOW.Stops do
		assert(not stops[stop], `the boot stops at "{stop}" twice`)
		stops[stop] = true
	end
end

return FLOW
