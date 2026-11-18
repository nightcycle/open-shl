--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local HUDTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/HUD/Types")
export type ButtonInfo = HUDTypes.ButtonInfo
export type Buttons = HUDTypes.Buttons
-- Constants
-- what's on the hud is the game's own, the buttons of another game are never required
local BUTTONS: Buttons = GameDefinition.pick({
	shl1 = function(): Buttons
		error(`shl1 has no hud buttons yet`)
	end,
	shl2 = function(): Buttons
		return require("@self/SHL2")
	end,
	shl3 = function(): Buttons
		return require("@self/SHL3")
	end,
})
assert(HUDTypes.Buttons(BUTTONS))
TableUtil.deepFreeze(BUTTONS)
-- Variables
-- References
-- Private Functions
-- Class
do
	-- a button is drawn under the name of its menu, so the second of a pair would take the place of the first
	local menuIds: { [PseudoEnum.MenuId]: true } = {}
	local columns: { { ButtonInfo } } = { BUTTONS.LEFT, BUTTONS.RIGHT }
	if BUTTONS.BUILD then
		table.insert(columns, { BUTTONS.BUILD })
	end
	for _, buttonInfos in columns do
		for _, buttonInfo in buttonInfos do
			assert(not menuIds[buttonInfo.MenuId], `the "{buttonInfo.MenuId}" button is on the hud twice`)
			menuIds[buttonInfo.MenuId] = true
		end
	end
end

return {
	BUTTONS = BUTTONS,
}
