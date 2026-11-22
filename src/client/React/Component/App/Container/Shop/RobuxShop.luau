--!strict
--!native
-- Services
local MarketplaceService = game:GetService("MarketplaceService")
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
-- Modules
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
-- Components
local RobuxShop = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/RobuxShop")
-- Hooks
local useIsMounted = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useIsMounted")
-- Contexts
-- Types
local ShopMenuTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ShopMenu/Types")
type ProductDefinition = ProductDefinition.ProductDefinition
export type Properties = ShopMenuTypes.Properties
-- Constants
local PRODUCTS = ProductDefinition.list()
-- Variables
-- what a product cost when it was asked about, by its id. it's asked once, a shop that's opened again knows already
local Prices: { [string]: string } = table.freeze({})
-- References
-- Private Functions
local e = React.createElement

-- nil where nobody could be asked or nothing is charged for it, the card stays on the price it was written down with
local function getPrice(definition: ProductDefinition): string?
	local isOk, info = pcall(function(): any
		return MarketplaceService:GetProductInfoAsync(definition.LegacyId, Enum.InfoType.Product)
	end)
	if not isOk or type(info) ~= "table" then
		return nil
	end
	local price: unknown = info.PriceInRobux
	if type(price) ~= "number" then
		return nil
	end
	return `{price} R$`
end
-- Class
-- the app tells every shop the same things, this one is also told what's sold + what it costs today
return function(props: Properties): React.ReactNode
	local prices: { [string]: string }, setPrices: ({ [string]: string }) -> () = React.useState(Prices)
	local isMountedRef = useIsMounted()

	-- only the credits were priced on their card, what a pass costs is said by the prompt
	React.useEffect(function()
		for _, definition in PRODUCTS do
			if ProductDefinition.getIfGamePass(definition) or Prices[definition.Id] then
				continue
			end
			task.spawn(function()
				local price = getPrice(definition)
				if not price then
					return
				end
				local out = table.clone(Prices)
				out[definition.Id] = price
				table.freeze(out)
				Prices = out
				if isMountedRef.current then
					setPrices(out)
				end
			end)
		end
		return function() end
	end, {})

	return e(
		RobuxShop,
		{
			AnchorPoint = props.AnchorPoint,
			Position = props.Position,
			Size = props.Size,
			SizeConstraint = props.SizeConstraint,
			Products = PRODUCTS,
			Prices = prices,
			ErrorMessage = props.ErrorMessage,
			OnAction = props.OnAction,
		} :: RobuxShop.Properties
	)
end
