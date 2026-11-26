--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local EdgeHUD = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/EdgeHUD")
local ServerModeToggle = require("@self/ServerModeToggle")
-- Hooks
local useCharacterAttribute =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useCharacterAttribute")
local useIsFighting = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsFighting")
local useIsPVP = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsPVP")
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
-- how faded the way to the characters is drawn for as long as the avatar is in a fight
local FIGHTING_FADE = 0.7
-- whoever is held has the switch slid out of reach until they got away
local JAILED_AWAY: { [PseudoEnum.MenuId]: true } = table.freeze({
	[PseudoEnum.MenuId.Swap] = true :: true,
})
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- the buttons of the game, without the one for changing sides in a place that has none
local function getButtons(hasSides: boolean): EdgeHUD.Buttons
	if hasSides then
		return CONSTANTS.BUTTONS
	end
	local function list(buttonInfos: { HUDTypes.ButtonInfo }): { HUDTypes.ButtonInfo }
		local out: { HUDTypes.ButtonInfo } = {}
		for _, buttonInfo in buttonInfos do
			if buttonInfo.MenuId ~= PseudoEnum.MenuId.Team then
				table.insert(out, buttonInfo)
			end
		end
		table.freeze(out)
		return out
	end
	local out: EdgeHUD.Buttons = {
		LEFT = list(CONSTANTS.BUTTONS.LEFT),
		RIGHT = list(CONSTANTS.BUTTONS.RIGHT),
	}
	table.freeze(out)
	return out
end
-- Class
for _, buttonInfos in { CONSTANTS.BUTTONS.LEFT, CONSTANTS.BUTTONS.RIGHT } do
	for _, buttonInfo in buttonInfos do
		assert(buttonInfo.Position, `the "{buttonInfo.MenuId}" button has no height on its edge`)
	end
end

-- the app tells every hud the same things, this one only has a use for where it's put + what's pressed
return function(props: Properties): React.ReactNode
	local isSwapCooling: boolean?, setIsSwapCooling: (boolean?) -> () = useTimedState(SWAP_COOLDOWN)
	local isFighting = useIsFighting()
	-- only a villain is ever held, + only where there are sides: the old place took its switch away the same way
	local isJailed = useCharacterAttribute(AttributeDefinition.IsJailed) == true
	-- a place where nobody fights has no sides, the hud of the old one went without the button there. the button
	-- goes + comes back with them where the owner of a server changes its mind
	local hasSides = useIsPVP()
	local buttons = React.useMemo(function(): EdgeHUD.Buttons
		return getButtons(hasSides)
	end, { hasSides })
	local fades = React.useMemo(function(): { [PseudoEnum.MenuId]: number }
		local out: { [PseudoEnum.MenuId]: number } = {}
		if isSwapCooling then
			out[PseudoEnum.MenuId.Swap] = SWAP_FADE
		end
		-- whoever is in a fight doesn't get to walk off as somebody else: the manager + the editor behind it are
		-- menus the server keeps them out of until it's over
		if isFighting then
			out[PseudoEnum.MenuId.Characters] = FIGHTING_FADE
		end
		table.freeze(out)
		return out
	end, { isSwapCooling, isFighting })

	return e("Frame", {
		Active = false,
		BackgroundTransparency = 1,
		Size = props.Size,
		ZIndex = props.ZIndex,
	}, {
		Buttons = e(
			EdgeHUD,
			{
				Size = UDim2.fromScale(1, 1),
				Buttons = buttons,
				Fades = fades,
				Away = if isJailed then JAILED_AWAY else nil,
				OnAction = function(action: EdgeHUD.ActionInfo)
					if action.Type == "Press" then
						if action.MenuId == PseudoEnum.MenuId.Swap then
							setIsSwapCooling(true)
						end
						props.OnClick(action.MenuId)
					end
				end,
			} :: EdgeHUD.Properties
		),
		-- it comes + goes with the hud, the way the old place had it: no menu has it
		ServerModeToggle = e(ServerModeToggle, {}),
	})
end
