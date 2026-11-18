--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local ReactRoblox = require("@game/ReplicatedStorage/Packages/ReactRoblox")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local SessionEntitlementsContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Entitlements")
local SessionGemsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Gems")
-- Types
type EntitlementKey = SessionEntitlementsContext.EntitlementKey
-- Constants
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return UILabs.CreateReactStory({
	react = React,
	reactRoblox = ReactRoblox,
	controls = {},
}, function(props)
	local isOpen, setIsOpen = React.useState(true)
	local credits, setCredits = React.useState(ProductDefinition.STARTING_BALANCES.Credits)
	local gems, setGems = React.useState(ProductDefinition.STARTING_BALANCES.Gems)
	local entitlements: { EntitlementKey }, setEntitlements: ({ EntitlementKey }) -> () =
		React.useState(table.freeze({}) :: { EntitlementKey })
	local errorMessage: string?, setErrorMessage: (string?) -> () = React.useState(nil :: string?)

	return e(SessionCreditsContext.Provider, {
		value = credits,
	}, {
		Gems = e(SessionGemsContext.Provider, {
			value = gems,
		}, {
			Entitlements = e(SessionEntitlementsContext.Provider, {
				value = entitlements,
			}, {
				Frame = e("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
				}, {
					Open = e(
						"TextButton",
						{
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = Color3.fromRGB(0, 80, 229),
							BorderColor3 = Color3.fromRGB(27, 42, 53),
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
							Position = UDim2.fromScale(0.04, 0.65),
							Size = UDim2.fromScale(0.08, 0.08),
							SizeConstraint = Enum.SizeConstraint.RelativeYY,
							Text = isOpen and "Close" or "Open",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							[React.Event.Activated] = function()
								setErrorMessage(nil)
								setIsOpen(not isOpen)
							end,
						} :: RobloxComponents.TextButtonProperties
					),
					Menu = isOpen and e(
						ParentComponent,
						{
							AnchorPoint = Vector2.new(0, 0.5),
							Position = UDim2.fromScale(0.35, 0.5),
							Size = UDim2.fromScale(0.3, 0.3),
							ErrorMessage = errorMessage,
							OnAction = function(action: ParentComponent.ActionInfo)
								if action.Type == "Purchase" then
									local definitionRes = ProductDefinition.get(action.ProductId)
									if definitionRes.IsErr then
										setErrorMessage(definitionRes.Value)
										return
									end
									local definition = definitionRes.Value
									local grant = definition.Grant
									if grant.Type == "Currency" then
										if grant.Currency == PseudoEnum.Currency.Credits then
											setCredits(credits + grant.Amount)
										else
											setGems(gems + grant.Amount)
										end
										setErrorMessage(nil)
									elseif grant.Type == "Entitlement" then
										if table.find(entitlements, grant.Key) then
											setErrorMessage(`"{definition.Name}" is already owned`)
											return
										end
										local out = table.clone(entitlements)
										table.insert(out, grant.Key)
										table.freeze(out)
										setEntitlements(out)
										setErrorMessage(nil)
									end
								elseif action.Type == "Exit" then
									setErrorMessage(nil)
									setIsOpen(false)
								end
							end,
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
						} :: ParentComponent.Properties
					),
				}),
			}),
		}),
	})
end)
