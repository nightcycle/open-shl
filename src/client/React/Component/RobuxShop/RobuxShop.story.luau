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
local StyleStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Story")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local SessionEntitlementsContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Entitlements")
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type EntitlementKey = SessionEntitlementsContext.EntitlementKey
type ProductCatalogue = EconomyType.ProductCatalogue
-- Constants
-- the products of the game the layout was made for, whichever game the place is built for: they're nothing but values
local CATALOGUE: ProductCatalogue = require("@game/ReplicatedStorage/Shared/Definition/Product/SHL3")
local PRODUCTS = CATALOGUE.Definitions
-- what the credits would cost if somebody had changed every price since it was written down
local LIVE_PRICES: { [string]: string } = table.freeze({
	credits_500 = "49 R$",
	credits_2500 = "199 R$",
	credits_5000 = "349 R$",
	credits_10000 = "499 R$",
	credits_25000 = "1299 R$",
	credits_50000 = "2399 R$",
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
		IsEveryPassOwned = UILabs.Boolean(false),
		HasLivePrices = UILabs.Boolean(false),
		ErrorMessage = UILabs.String(""),
	},
}, function(props)
	local isOpen, setIsOpen = React.useState(true)
	local credits, setCredits = React.useState(CATALOGUE.StartingBalances.Credits)
	-- what was bought in here, a pass is had from the press on
	local bought: { EntitlementKey }, setBought: ({ EntitlementKey }) -> () =
		React.useState(table.freeze({}) :: { EntitlementKey })
	local errorMessage: string?, setErrorMessage: (string?) -> () = React.useState(nil :: string?)

	local isEveryPassOwned: boolean = props.controls.IsEveryPassOwned
	local entitlements = React.useMemo(function(): { EntitlementKey }
		if not isEveryPassOwned then
			return bought
		end
		local out: { EntitlementKey } = {}
		for _, definition in PRODUCTS do
			local grant = definition.Grant
			if grant.Type == "Entitlement" then
				table.insert(out, grant.Key)
			end
		end
		table.freeze(out)
		return out
	end, { isEveryPassOwned :: any, bought })
	local controlMessage: string = props.controls.ErrorMessage

	return StyleStory.provide(props.controls.Style, {
		Credits = e(SessionCreditsContext.Provider, {
			value = credits,
		}, {
			Entitlements = e(SessionEntitlementsContext.Provider, {
				value = entitlements,
			}, {
				Screen = e("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = Color3.fromRGB(127, 127, 127),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
				}, {
					-- stands in for the button of the hud
					Open = e(
						"TextButton",
						{
							AnchorPoint = Vector2.new(1, 0.5),
							BackgroundColor3 = Color3.fromRGB(0, 80, 229),
							BorderColor3 = Color3.fromRGB(27, 42, 53),
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
							Position = UDim2.new(1, -10, 0.7, 0),
							Size = UDim2.fromScale(0.075, 0.075),
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
							-- where the container of its game puts it
							AnchorPoint = Vector2.new(0.5, 0.5),
							Position = UDim2.fromScale(0.5, 0.5),
							Size = UDim2.fromScale(0.45, 0.3),
							SizeConstraint = Enum.SizeConstraint.RelativeXX,
							Products = PRODUCTS,
							Prices = if props.controls.HasLivePrices then LIVE_PRICES else nil,
							ErrorMessage = if controlMessage ~= "" then controlMessage else errorMessage,
							OnAction = function(action: ParentComponent.ActionInfo)
								if action.Type == "Purchase" then
									for _, definition in PRODUCTS do
										if definition.Id ~= action.ProductId then
											continue
										end
										local grant = definition.Grant
										if grant.Type == "Currency" then
											setCredits(credits + grant.Amount)
											setErrorMessage(nil)
										elseif table.find(bought, grant.Key) then
											setErrorMessage(`"{definition.Name}" is already owned`)
										else
											local out = table.clone(bought)
											table.insert(out, grant.Key)
											table.freeze(out)
											setBought(out)
											setErrorMessage(nil)
										end
										return
									end
									setErrorMessage(`no product "{action.ProductId}"`)
								elseif action.Type == "Exit" then
									setErrorMessage(nil)
									setIsOpen(false)
								end
							end,
						} :: ParentComponent.Properties
					),
				}),
			}),
		}),
	})
end)
