--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local BalanceCounter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/BalanceCounter")
local ExitButton = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ExitButton")
local ProductCard = require("@self/ProductCard")
-- Hooks
local useSlide = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSlide")
-- Contexts
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local SessionEntitlementsContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Entitlements")
local SessionGemsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Gems")
-- Types
export type ProductDefinition = ProductDefinition.ProductDefinition
export type ShopTab = ProductDefinition.ShopTab
export type ActionInfo =
	{
		Type: "Purchase",
		ProductId: string,
	}
	| {
		Type: "Exit",
	}

export type Properties = RobloxComponents.FrameProperties & {
	ErrorMessage: string?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
local STRIP_SIZE = 0.075
local TAB_TEXT_SIZE = 18
local OWNED_TEXT = "Owned"
local LABEL_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local SLIDE_OFFSET = UDim2.fromScale(0.7, 0)
local SLIDE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
return function(props: Properties)
	local credits = React.useContext(SessionCreditsContext)
	local gems = React.useContext(SessionGemsContext)
	local entitlements = React.useContext(SessionEntitlementsContext)
	local currentTab: ShopTab, setCurrentTab: (ShopTab) -> () = React.useState("Credits" :: ShopTab)
	local productDefinitions = React.useMemo(function(): { ProductDefinition }
		return ProductDefinition.list(currentTab)
	end, { currentTab })

	local openPosition = props.Position or UDim2.new()
	local frameRef, initialPosition, close = useSlide(
		openPosition,
		openPosition - SLIDE_OFFSET,
		SLIDE_TWEEN_INFO,
		function()
			props.OnAction({
				Type = "Exit",
			})
		end
	)

	local tabs: { [string]: React.ReactNode } = {}
	local cards: { [string]: React.ReactNode } = {}
	for i, tabInfo in CONSTANTS.TABS do
		local isSelected = tabInfo.Tab == currentTab
		tabs[`{tabInfo.Tab}Button`] = e(
			"TextButton",
			{
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = tabInfo.BackgroundColor3,
				BackgroundTransparency = isSelected and 0 or 0.5,
				BorderColor3 = Color3.fromRGB(27, 42, 53),
				FontFace = LABEL_FONT,
				Position = UDim2.fromScale((i - 1) / #CONSTANTS.TABS, 0),
				Size = UDim2.fromScale(1 / #CONSTANTS.TABS, STRIP_SIZE),
				Text = tabInfo.Text,
				TextColor3 = Color3.fromRGB(27, 42, 53),
				TextScaled = true,
				[React.Event.Activated] = function()
					setCurrentTab(tabInfo.Tab)
				end,
			} :: RobloxComponents.TextButtonProperties,
			{
				UITextSizeConstraint = e("UITextSizeConstraint", {
					MaxTextSize = TAB_TEXT_SIZE,
				}),
			}
		)
		if not isSelected then
			continue
		end

		for row, definition in productDefinitions do
			local rowPosition = tabInfo.RowPositions[row]
			if not rowPosition then
				warn(`no row for "{definition.Id}"`)
				continue
			end
			local grant = definition.Grant
			local isOwned = grant.Type == "Entitlement" and table.find(entitlements, grant.Key) ~= nil
			cards[definition.Id] = e(
				ProductCard,
				{
					Position = UDim2.fromScale(0, rowPosition),
					Title = definition.Name,
					PriceText = isOwned and OWNED_TEXT or definition.LegacyPriceText,
					CardColor3 = tabInfo.CardColor3,
					IsOwned = isOwned,
					OnClick = function()
						props.OnAction({
							Type = "Purchase",
							ProductId = definition.Id,
						})
					end,
				} :: ProductCard.Properties
			)
		end
	end

	return e(RobloxComponents.Frame(
		{
			ref = frameRef,
			-- a click that lands on the panel isn't one on the world behind it
			Active = true,
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.3,
			BorderColor3 = Color3.fromRGB(27, 42, 53),
			Position = initialPosition,
		} :: RobloxComponents.FrameProperties,
		props,
		{
			CreditCount = e(
				BalanceCounter,
				{
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.fromScale(1, -2 * STRIP_SIZE),
					Size = UDim2.fromScale(1, STRIP_SIZE),
					Currency = PseudoEnum.Currency.Credits,
					Balance = credits,
				} :: BalanceCounter.Properties
			),
			GemCount = e(
				BalanceCounter,
				{
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.fromScale(1, -STRIP_SIZE),
					Size = UDim2.fromScale(1, STRIP_SIZE),
					Currency = PseudoEnum.Currency.Gems,
					Balance = gems,
				} :: BalanceCounter.Properties
			),
			Tabs = e(React.Fragment, {}, tabs),
			Products = e("Frame", {
				BackgroundTransparency = 1,
				Size = UDim2.fromScale(1, 1),
			}, {
				Cards = e(React.Fragment, {}, cards),
			}),
			ErrorMessage = props.ErrorMessage and e("TextLabel", {
				BackgroundColor3 = Color3.fromRGB(151, 75, 75),
				BorderSizePixel = 0,
				FontFace = LABEL_FONT,
				Position = UDim2.fromScale(0, 1),
				Size = UDim2.fromScale(1, STRIP_SIZE),
				Text = props.ErrorMessage,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),
			Exit = e(
				ExitButton,
				{
					Position = UDim2.fromScale(0, 0),
					ZIndex = 3,
					[React.Event.Activated] = close,
				} :: ExitButton.Properties
			),
		}
	))
end
