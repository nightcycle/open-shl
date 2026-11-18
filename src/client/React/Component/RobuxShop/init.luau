--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
local BalanceCounter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/BalanceCounter")
local Card = require("@self/Card")
-- Hooks
-- Contexts
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local SessionEntitlementsContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Entitlements")
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local ShopMenuTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ShopMenu/Types")
export type ProductDefinition = EconomyType.ProductDefinition
export type ShopTab = EconomyType.ShopTab
export type ActionInfo = ShopMenuTypes.ActionInfo
export type Properties = RobloxComponents.FrameProperties & {
	-- what's sold. a card is drawn for each one the art has a card for
	Products: { ProductDefinition },
	-- what a product costs today by its id, one that's left out shows the price it was written down with
	Prices: { [string]: string }?,
	ErrorMessage: string?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
local WHITE = Color3.new(1, 1, 1)
-- the art is a square canvas with the panel drawn across its middle, 1.8 times as tall as the frame it's centered on
local PANEL_IMAGE = Image.shl3.ui.shop["panel.png"]
local PANEL_SIZE = UDim2.fromScale(1.8, 1.8)
-- the rule under the cards is the thin sidebar of the other panels laid on its side
local RULE_IMAGE = Image.shl3.ui.common["sidebar-thin.png"]
local RULE_POSITION = UDim2.fromScale(0.5, 0.725)
local RULE_SIZE = UDim2.fromScale(1.15, 0.92)
local RULE_ROTATION = 90
-- the tag that covers the title drawn into the art
local TITLE_TEXT = "SHOP"
local TITLE_POSITION = UDim2.fromScale(0.5, 0.126)
local TITLE_SIZE = UDim2.fromScale(0.35, 0.0939)
local MENU_POSITION = UDim2.fromScale(0.116, 0.193)
local MENU_SIZE = UDim2.fromScale(0.7661, 0.1046)
local MENU_PADDING = UDim.new(0.1, 0)
local TAB_SIZE = UDim2.fromScale(0.325, 0.917)
-- what the tag of a tab stands on, picked + not
local SELECTED_TAG_COLOR = Color3.fromRGB(47, 153, 190)
local TAG_COLOR = Color3.fromRGB(209, 209, 209)
-- the lists hang in a frame of their own, which is as wide as the frame of the panel is
local HOLDER_POSITION = UDim2.fromScale(0.5, 0.4408)
local HOLDER_SIZE = UDim2.fromScale(0.92, 0.744)
local LIST_POSITION = UDim2.fromScale(0.5, 0.932)
local LIST_SIZE = UDim2.fromScale(1.087, 0.6112)
-- three lists wide whatever is in it
local CANVAS_SIZE = UDim2.fromScale(3, 0)
local SCROLL_BAR_IMAGE = Image.shl3.ui.shop["scroll-bar.png"]
-- how thick the scroll bar is in scale of the width of its list + in pixels until that's known
local SCROLL_BAR_SCALE = 0.03
local SCROLL_BAR_THICKNESS = 14
-- the exit of this panel is the old one of the kit, hung on the top right corner of the art
local EXIT_IMAGE = Image.ui["exit.png"]
local EXIT_ANCHOR_POINT = Vector2.new(0.7, 0.3)
local EXIT_POSITION = UDim2.fromScale(1.11, 0.0568)
local EXIT_SIZE = UDim2.fromScale(0.08, 0.08)
-- the legacy panel never said what a player has: the balance sits on the field the art leaves under the scroll bar
local BALANCE_POSITION = UDim2.fromScale(0.5, 0.986)
local BALANCE_SIZE = UDim2.fromScale(0.35, 0.05)
-- nor what went wrong, that's said under the art
local ERROR_POSITION = UDim2.fromScale(0.5, 1.08)
local ERROR_SIZE = UDim2.fromScale(0.9, 0.045)
local OWNED_TEXT = "OWNED"
-- which tab the art has the card of a product on, by the id of the product
local CARD_TABS: { [string]: ShopTab } = {}
for _, tabInfo in CONSTANTS.TABS do
	for _, cardInfo in tabInfo.Cards do
		CARD_TABS[cardInfo.ProductId] = tabInfo.Tab
	end
end
table.freeze(CARD_TABS)
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the shop of the legacy place: one panel in the middle of the screen with a row of square cards for each of its tabs
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local credits = React.useContext(SessionCreditsContext)
	local entitlements = React.useContext(SessionEntitlementsContext)
	local currentTab: ShopTab, setCurrentTab: (ShopTab) -> () = React.useState(CONSTANTS.TABS[1].Tab)
	local scrollBarThickness: number, setScrollBarThickness: (number) -> () = React.useState(SCROLL_BAR_THICKNESS)
	local function measure(scrollingFrame: ScrollingFrame)
		setScrollBarThickness(math.round(scrollingFrame.AbsoluteSize.X * SCROLL_BAR_SCALE))
	end

	local products = props.Products
	local definitions = React.useMemo(function(): { [string]: ProductDefinition }
		local out: { [string]: ProductDefinition } = {}
		for _, definition in products do
			out[definition.Id] = definition
			-- the art only has room for what the legacy place sold, the checker doesn't see a product that's added
			local cardTab = CARD_TABS[definition.Id]
			if not cardTab then
				warn(`no card for "{definition.Id}"`)
			elseif cardTab ~= definition.Tab then
				warn(`the card of "{definition.Id}" is on the "{cardTab}" tab, the product on "{definition.Tab}"`)
			end
		end
		table.freeze(out)
		return out
	end, { products })

	local prices = props.Prices
	local tabs: { [string]: React.ReactNode } = {}
	local lists: { [string]: React.ReactNode } = {}
	for i, tabInfo in CONSTANTS.TABS do
		local isSelected = tabInfo.Tab == currentTab
		tabs[`{tabInfo.Tab}Button`] = e(
			"ImageButton",
			{
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				LayoutOrder = i,
				Size = TAB_SIZE,
				[React.Event.Activated] = function()
					setCurrentTab(tabInfo.Tab)
				end,
			} :: RobloxComponents.ImageButtonProperties,
			{
				Art = e(
					"ImageLabel",
					{
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						ImageColor3 = isSelected and style.Palette.AccentLight or WHITE,
						ImageContent = Content.fromUri(tabInfo.Image),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
						ZIndex = 1,
					} :: RobloxComponents.ImageLabelProperties
				),
				Tag = e(
					"TextLabel",
					{
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundColor3 = isSelected and SELECTED_TAG_COLOR or TAG_COLOR,
						BorderSizePixel = 0,
						FontFace = style.Fonts.Heading,
						Position = UDim2.fromScale(0.5, 0.5),
						Size = tabInfo.TagSize,
						Text = tabInfo.Text,
						TextColor3 = style.Palette.TextOnAccent,
						TextScaled = true,
						TextWrapped = true,
						ZIndex = 2,
					} :: RobloxComponents.TextLabelProperties
				),
			}
		)

		local cards: { [string]: React.ReactNode } = {}
		for order, cardInfo in tabInfo.Cards do
			-- a card of something that isn't sold stays out of the row
			local definition = definitions[cardInfo.ProductId]
			if not definition then
				continue
			end
			local grant = definition.Grant
			local isOwned = grant.Type == "Entitlement" and table.find(entitlements, grant.Key) ~= nil
			local priceText = prices and prices[definition.Id] or definition.LegacyPriceText
			-- a pass was never priced on its card, so the only thing its sticker has to say is that it's had
			local stickerText: string? = if isOwned then OWNED_TEXT elseif priceText ~= "" then priceText else nil
			cards[definition.Id] = e(
				Card,
				{
					LayoutOrder = order,
					Size = tabInfo.CardSize,
					SizeConstraint = tabInfo.CardSizeConstraint,
					Title = definition.Name,
					Tile = tabInfo.Tile,
					Caption = tabInfo.Caption,
					Pictures = cardInfo.Pictures,
					Button = cardInfo.Button,
					StickerText = stickerText,
					IsFaded = isOwned,
					OnClick = function()
						props.OnAction({
							Type = "Purchase",
							ProductId = definition.Id,
						})
					end,
				} :: Card.Properties
			)
		end
		-- both stay mounted, so each is where it was scrolled to when its tab is picked again
		lists[tabInfo.Tab] = e(
			"ScrollingFrame",
			{
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				BottomImage = "",
				CanvasSize = CANVAS_SIZE,
				ElasticBehavior = Enum.ElasticBehavior.Never,
				MidImage = SCROLL_BAR_IMAGE,
				Position = LIST_POSITION,
				-- the engine starts a scroll bar out black
				ScrollBarImageColor3 = WHITE,
				ScrollBarThickness = scrollBarThickness,
				ScrollingDirection = Enum.ScrollingDirection.X,
				Size = LIST_SIZE,
				TopImage = "",
				Visible = isSelected,
				[React.Change.AbsoluteSize] = measure,
			} :: RobloxComponents.ScrollingFrameProperties,
			{
				UIListLayout = e("UIListLayout", {
					FillDirection = Enum.FillDirection.Horizontal,
					HorizontalAlignment = Enum.HorizontalAlignment.Left,
					Padding = tabInfo.Padding,
					SortOrder = Enum.SortOrder.LayoutOrder,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				Cards = e(React.Fragment, {}, cards),
			}
		)
	end

	return e(RobloxComponents.Frame(
		{
			-- a click that lands on the panel isn't one on the world behind it
			Active = true,
			BackgroundTransparency = 1,
		},
		props,
		{
			Art = e(
				"ImageLabel",
				{
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ImageContent = Content.fromUri(PANEL_IMAGE),
					Position = UDim2.fromScale(0.5, 0.5),
					Size = PANEL_SIZE,
					SizeConstraint = Enum.SizeConstraint.RelativeYY,
					ZIndex = 1,
				} :: RobloxComponents.ImageLabelProperties,
				{
					Rule = e(
						"ImageLabel",
						{
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundTransparency = 1,
							ImageContent = Content.fromUri(RULE_IMAGE),
							Position = RULE_POSITION,
							Rotation = RULE_ROTATION,
							Size = RULE_SIZE,
						} :: RobloxComponents.ImageLabelProperties
					),
				}
			),
			Lists = e(
				"Frame",
				{
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = HOLDER_POSITION,
					Size = HOLDER_SIZE,
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					ZIndex = 2,
				} :: RobloxComponents.FrameProperties,
				lists
			),
			Balance = e(
				BalanceCounter,
				{
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = BALANCE_POSITION,
					Size = BALANCE_SIZE,
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					ZIndex = 2,
					Currency = PseudoEnum.Currency.Credits,
					Balance = credits,
				} :: BalanceCounter.Properties
			),
			Title = e(
				"TextLabel",
				{
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = style.Palette.Accent,
					BorderSizePixel = 0,
					FontFace = style.Fonts.Heading,
					Position = TITLE_POSITION,
					Size = TITLE_SIZE,
					Text = TITLE_TEXT,
					TextColor3 = style.Palette.TextOnAccent,
					TextScaled = true,
					TextWrapped = true,
					ZIndex = 3,
				} :: RobloxComponents.TextLabelProperties
			),
			-- over the lists, the top of which reaches under the tabs
			Menu = e(
				"Frame",
				{
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					Position = MENU_POSITION,
					Size = MENU_SIZE,
					ZIndex = 3,
				} :: RobloxComponents.FrameProperties,
				{
					UIListLayout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						Padding = MENU_PADDING,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Top,
					}),
					Tabs = e(React.Fragment, {}, tabs),
				}
			),
			ErrorMessage = props.ErrorMessage and e(
				"TextLabel",
				{
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = style.Palette.Negative,
					BorderSizePixel = 0,
					FontFace = style.Fonts.Heading,
					Position = ERROR_POSITION,
					Size = ERROR_SIZE,
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = props.ErrorMessage,
					TextColor3 = style.Palette.TextOnAccent,
					TextScaled = true,
					ZIndex = 3,
				} :: RobloxComponents.TextLabelProperties
			),
			-- the panel was never slid or grown, it's there + then it isn't
			Exit = e(
				"ImageButton",
				{
					AnchorPoint = EXIT_ANCHOR_POINT,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ImageContent = Content.fromUri(EXIT_IMAGE),
					Position = EXIT_POSITION,
					Size = EXIT_SIZE,
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					ZIndex = 4,
					[React.Event.Activated] = function()
						props.OnAction({
							Type = "Exit",
						})
					end,
				} :: RobloxComponents.ImageButtonProperties
			),
		}
	))
end
