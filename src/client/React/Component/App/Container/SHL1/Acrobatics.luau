--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local AcrobaticsService = require("@game/StarterPlayer/StarterPlayerScripts/Client/Service/Acrobatics")
-- Components
local Acrobatics = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Acrobatics")
-- Hooks
local useLocalCharacter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useLocalCharacter")
-- Contexts
local AppIsGameplayHudVisibleContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/App/IsGameplayHudVisible")
local SessionActiveIdentityKeyContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveIdentityKey")
-- Types
export type Properties = {}
-- Constants
-- the identity the powers are carried by: the flips are the hero's the way those are
local HERO_KEY: SessionActiveIdentityKeyContext.IdentityKey = "Main"
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the panel is up with the hud for as long as the hero is out + gone with either: the old place left it up for the
-- civilian with buttons that did nothing. where it was dragged to is kept for the visit, it's back at the right edge
-- with the next
return function(): React.ReactNode
	assert(AcrobaticsService.IsInitialized, `the acrobatics service isn't initialized`)
	local isGameplayHudVisible = React.useContext(AppIsGameplayHudVisibleContext)
	local identityKey = React.useContext(SessionActiveIdentityKeyContext)
	local avatar = useLocalCharacter()
	local boxPosition: UDim2?, setBoxPosition: (UDim2?) -> () = React.useState(nil :: UDim2?)
	if not isGameplayHudVisible or not avatar or identityKey ~= HERO_KEY then
		return nil
	end
	return e(
		Acrobatics,
		{
			Size = UDim2.fromScale(1, 1),
			BoxPosition = boxPosition,
			OnAction = function(action: Acrobatics.ActionInfo)
				if action.Type == "Play" then
					-- a press that comes at the wrong time does nothing, as it always did
					AcrobaticsService:Play(action.MoveId)
				elseif action.Type == "Fix" then
					AcrobaticsService:Fix()
				elseif action.Type == "Drag" then
					setBoxPosition(action.Position)
				end
			end,
		} :: Acrobatics.Properties
	)
end
