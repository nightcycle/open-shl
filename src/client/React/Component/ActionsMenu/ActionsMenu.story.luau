--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local SessionActiveIdentityKeyContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveIdentityKey")
-- Types
type IdentityKey = SessionActiveIdentityKeyContext.IdentityKey
type ExpressionId = ParentComponent.ExpressionId
type EmoteId = ParentComponent.EmoteId
-- Constants
local IDENTITY_KEYS: { IdentityKey } = { "Main", "Secret" }
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {
		IdentityKey = UILabs.Choose(IDENTITY_KEYS),
	},
}, function(props)
	local expressionId: ExpressionId?, setExpressionId: (ExpressionId?) -> () = React.useState(nil :: ExpressionId?)
	local emoteId: EmoteId?, setEmoteId: (EmoteId?) -> () = React.useState(nil :: EmoteId?)
	local isMasked, setIsMasked = React.useState(true)
	local isHandcuffed, setIsHandcuffed = React.useState(false)
	local isApartmentLocked, setIsApartmentLocked = React.useState(true)
	local openCount, setOpenCount = React.useState(1)
	local identityKey: IdentityKey = props.controls.IdentityKey :: IdentityKey

	-- there's nothing to go back to here, so a panel that was closed slides in anew
	local menus: { [string]: React.ReactNode } = {}
	menus[`Menu-{openCount}`] = e(
		ParentComponent,
		{
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.3, 0.5),
			Size = UDim2.fromScale(0.4, 0.5),
			ExpressionId = expressionId,
			EmoteId = emoteId,
			IsMasked = isMasked or identityKey ~= "Main",
			IsHandcuffed = isHandcuffed,
			IsApartmentLocked = isApartmentLocked,
			OnAction = function(action: ParentComponent.ActionInfo)
				if action.Type == "SetExpression" then
					setExpressionId(action.ExpressionId)
				elseif action.Type == "SetEmote" then
					setEmoteId(action.EmoteId)
					-- the cuffs come off for an emote
					if action.EmoteId then
						setIsHandcuffed(false)
					end
				elseif action.Type == "SetMasked" then
					setIsMasked(action.IsMasked)
				elseif action.Type == "SetHandcuffed" then
					setIsHandcuffed(action.IsHandcuffed)
					-- an emote ends as the cuffs go on
					if action.IsHandcuffed then
						setEmoteId(nil)
					end
				elseif action.Type == "SetApartmentLocked" then
					setIsApartmentLocked(action.IsApartmentLocked)
				elseif action.Type == "Exit" then
					setOpenCount(openCount + 1)
				end
			end,
			SizeConstraint = Enum.SizeConstraint.RelativeXY,
		} :: ParentComponent.Properties
	)

	return e(SessionActiveIdentityKeyContext.Provider, {
		value = identityKey,
	}, menus)
end)
