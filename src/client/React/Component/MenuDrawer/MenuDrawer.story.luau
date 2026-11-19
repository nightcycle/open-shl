--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		Style = StyleStory.newControl("shl1"),
		Credits = UILabs.Number(123),
		HasAvatar = UILabs.Boolean(true),
		IsFighting = UILabs.Boolean(false),
		IsMaskDead = UILabs.Boolean(true),
	},
}, function(props)
	local isOpen, setIsOpen = React.useState(false)
	local isShopOpen, setIsShopOpen = React.useState(false)
	local isHero, setIsHero = React.useState(false)
	local isPeaceful, setIsPeaceful = React.useState(false)
	local pressed: ParentComponent.ActionType?, setPressed: (ParentComponent.ActionType?) -> () =
		React.useState(nil :: ParentComponent.ActionType?)

	local isFighting: boolean = props.controls.IsFighting
	local isMaskDead: boolean = props.controls.IsMaskDead
	local dead = React.useMemo(function(): { [ParentComponent.ActionType]: boolean }
		local out: { [ParentComponent.ActionType]: boolean } = {
			ToggleMask = isMaskDead,
			-- whoever is in a fight doesn't get to walk off as somebody else
			Saves = isFighting,
			NewCharacter = isFighting,
		}
		table.freeze(out)
		return out
	end, { isFighting, isMaskDead })

	return StyleStory.provide(props.controls.Style, {
		Credits = e(SessionCreditsContext.Provider, {
			value = props.controls.Credits,
		}, {
			-- the drawer waits off the left edge of the screen, so the screen cuts off what's outside of it
			Screen = e("Frame", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(127, 127, 127),
				ClipsDescendants = true,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.9, 0.9),
			}, {
				-- stands in for what a line leads to, none of it is mounted in here
				Pressed = e("TextLabel", {
					AnchorPoint = Vector2.new(1, 1),
					BackgroundTransparency = 1,
					FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
					Position = UDim2.fromScale(1, 1),
					Size = UDim2.fromScale(0.4, 0.08),
					Text = if pressed then `pressed {pressed}` else "nothing pressed",
					TextColor3 = Color3.new(1, 1, 1),
					TextScaled = true,
				}),
				HUD = e(
					ParentComponent,
					{
						Size = UDim2.fromScale(1, 1),
						IsOpen = isOpen,
						IsShopOpen = isShopOpen,
						IsHero = if props.controls.HasAvatar then isHero else nil,
						IsPeaceful = isPeaceful,
						Dead = dead,
						OnAction = function(action: ParentComponent.ActionInfo)
							setPressed(action.Type)
							if action.Type == "Toggle" then
								setIsOpen(not isOpen)
							elseif action.Type == "Swap" then
								setIsHero(not isHero)
							elseif action.Type == "ToggleMode" then
								setIsPeaceful(not isPeaceful)
							elseif action.Type == "Saves" then
								setIsOpen(false)
							elseif action.Type == "Shop" then
								setIsShopOpen(not isShopOpen)
							end
						end,
					} :: ParentComponent.Properties
				),
			}),
		}),
	})
end)
