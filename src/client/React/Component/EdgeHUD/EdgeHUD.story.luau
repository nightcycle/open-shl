--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
-- Types
-- Constants
-- the buttons of the game the layout was made for, whichever game the place is built for: they're nothing but values
local BUTTONS: ParentComponent.Buttons =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/HUD/CONSTANTS/SHL3")
local SWAP_FADE = 0.5
local FIGHTING_FADE = 0.7
-- whoever is held has the switch slid out of reach
local JAILED_AWAY: { [PseudoEnum.MenuId]: true } = table.freeze({
	[PseudoEnum.MenuId.Swap] = true :: true,
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl3"),
		IsSwapCooling = UILabs.Boolean(false),
		IsFighting = UILabs.Boolean(false),
		-- off, it's the hud of a place where nobody fights: nobody is on a side there to change it
		HasSides = UILabs.Boolean(true),
		IsJailed = UILabs.Boolean(false),
	},
}, function(props)
	local pressedMenuId: PseudoEnum.MenuId?, setPressedMenuId: (PseudoEnum.MenuId?) -> () =
		React.useState(nil :: PseudoEnum.MenuId?)
	local isSwapCooling: boolean = props.controls.IsSwapCooling
	local isFighting: boolean = props.controls.IsFighting
	local hasSides: boolean = props.controls.HasSides
	local isJailed: boolean = props.controls.IsJailed
	local buttons = React.useMemo(function(): ParentComponent.Buttons
		if hasSides then
			return BUTTONS
		end
		local right = {}
		for _, buttonInfo in BUTTONS.RIGHT do
			if buttonInfo.MenuId ~= PseudoEnum.MenuId.Team then
				table.insert(right, buttonInfo)
			end
		end
		return {
			LEFT = BUTTONS.LEFT,
			RIGHT = right,
		}
	end, { hasSides })
	local fades = React.useMemo(function(): { [PseudoEnum.MenuId]: number }
		local out: { [PseudoEnum.MenuId]: number } = {}
		if isSwapCooling then
			out[PseudoEnum.MenuId.Swap] = SWAP_FADE
		end
		-- whoever is in a fight doesn't get to walk off as somebody else
		if isFighting then
			out[PseudoEnum.MenuId.Characters] = FIGHTING_FADE
		end
		table.freeze(out)
		return out
	end, { isSwapCooling, isFighting })

	return StyleStory.provide(props.controls.Style, {
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.75, 0.75),
		}, {
			-- stands in for the menus, none of them is mounted in here
			Pressed = e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.5, 0.1),
				Text = if pressedMenuId then `pressed {pressedMenuId}` else "nothing pressed",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),
			HUD = e(
				ParentComponent,
				{
					Size = UDim2.fromScale(1, 1),
					Buttons = buttons,
					Fades = fades,
					Away = if isJailed then JAILED_AWAY else nil,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "Press" then
							setPressedMenuId(action.MenuId)
						end
					end,
				} :: ParentComponent.Properties
			),
		}),
	})
end)
