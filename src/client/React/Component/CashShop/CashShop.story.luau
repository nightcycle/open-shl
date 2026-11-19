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
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type ProductCatalogue = EconomyType.ProductCatalogue
-- Constants
-- the products of the game the layout was made for, whichever game the place is built for: they're nothing but values
local CATALOGUE: ProductCatalogue = require("@game/ReplicatedStorage/Shared/Definition/Product/SHL1")
-- what the cash would cost if somebody had changed every price since it was written down
local LIVE_PRICES: { [string]: string } = table.freeze({
	credits_50 = "9 R$",
	credits_300 = "39 R$",
	credits_650 = "75 R$",
	credits_1400 = "149 R$",
	credits_7500 = "699 R$",
	credits_16000 = "1399 R$",
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
		Style = StyleStory.newControl("shl1"),
		HasLivePrices = UILabs.Boolean(false),
		ErrorMessage = UILabs.String(""),
	},
}, function(props)
	local bought: string?, setBought: (string?) -> () = React.useState(nil :: string?)

	local hasLivePrices: boolean = props.controls.HasLivePrices
	-- a row reads the way the old ones did: what's paid, then what's had for it
	local rows = React.useMemo(function(): { ParentComponent.RowInfo }
		local out: { ParentComponent.RowInfo } = {}
		for _, definition in CATALOGUE.Definitions do
			local price = if hasLivePrices then LIVE_PRICES[definition.Id] else nil
			table.insert(out, {
				ProductId = definition.Id,
				Text = `{price or definition.LegacyPriceText} = {definition.Name}`,
			})
		end
		table.freeze(out)
		return out
	end, { hasLivePrices })
	local controlMessage: string = props.controls.ErrorMessage

	return StyleStory.provide(props.controls.Style, {
		Screen = e("Frame", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.fromRGB(127, 127, 127),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0.9),
		}, {
			-- stands in for the prompt of the engine, nothing is paid for in here
			Bought = e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.fromScale(0.5, 0.08),
				Text = if bought then `asked for {bought}` else "nothing asked for",
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),
			-- where the panel was: across the middle of the screen from a fifth of the way down
			Menu = e(
				ParentComponent,
				{
					Position = UDim2.fromScale(0.3, 0.2),
					Size = UDim2.fromScale(0.4, 0.6),
					Rows = rows,
					ErrorMessage = if controlMessage ~= "" then controlMessage else nil,
					OnAction = function(action: ParentComponent.ActionInfo)
						if action.Type == "Purchase" then
							setBought(action.ProductId)
						end
					end,
				} :: ParentComponent.Properties
			),
		}),
	})
end)
