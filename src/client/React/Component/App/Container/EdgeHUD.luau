--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local EdgeHUD = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/EdgeHUD")
-- Hooks
local useTimedState = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useTimedState")
-- Contexts
-- Types
local HUDTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/HUD/Types")
export type Properties = HUDTypes.Properties
-- Constants
local CONSTANTS = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/HUD/CONSTANTS")
-- how long the switch can't be pressed again once it was + how faded it's drawn until then
local SWAP_COOLDOWN = 3.5
local SWAP_FADE = 0.5
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
for _, buttonInfos in { CONSTANTS.BUTTONS.LEFT, CONSTANTS.BUTTONS.RIGHT } do
	for _, buttonInfo in buttonInfos do
		assert(buttonInfo.Position, `the "{buttonInfo.MenuId}" button has no height on its edge`)
	end
end

-- the app tells every hud the same things, this one only has a use for where it's put + what's pressed
return function(props: Properties): React.ReactNode
	local isSwapCooling: boolean?, setIsSwapCooling: (boolean?) -> () = useTimedState(SWAP_COOLDOWN)
	local fades = React.useMemo(function(): { [PseudoEnum.MenuId]: number }
		local out: { [PseudoEnum.MenuId]: number } = {}
		if isSwapCooling then
			out[PseudoEnum.MenuId.Swap] = SWAP_FADE
		end
		table.freeze(out)
		return out
	end, { isSwapCooling })

	return e(
		EdgeHUD,
		{
			Size = props.Size,
			ZIndex = props.ZIndex,
			Buttons = CONSTANTS.BUTTONS,
			Fades = fades,
			OnAction = function(action: EdgeHUD.ActionInfo)
				if action.Type == "Press" then
					if action.MenuId == PseudoEnum.MenuId.Swap then
						setIsSwapCooling(true)
					end
					props.OnClick(action.MenuId)
				end
			end,
		} :: EdgeHUD.Properties
	)
end
