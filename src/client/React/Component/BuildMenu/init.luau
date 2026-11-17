--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local FurnitureDefinition = require("@game/ReplicatedStorage/Shared/Definition/Furniture")
local Image = require("@game/ReplicatedStorage/Generated/Image")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local ThemeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Theme")
-- Components
local BalanceCounter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/BalanceCounter")
local CategoryList = require("@self/CategoryList")
local ExitButton = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ExitButton")
local ItemCard = require("@self/ItemCard")
local ThemeSwatch = require("@self/ThemeSwatch")
local Thumbnail = require("@self/Thumbnail")
-- Hooks
local useSlide = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSlide")
-- Contexts
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local SessionGemsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Gems")
local SessionInventoryContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Inventory")
-- Types
local BuildTypes = require("@self/Types")
type FurnitureDefinition = BuildTypes.FurnitureDefinition
type FurnitureCategory = BuildTypes.FurnitureCategory
type ThemeDefinition = BuildTypes.ThemeDefinition
type Category = BuildTypes.Category
type CardState = BuildTypes.CardState
export type Refusal = BuildTypes.Refusal
export type ActionInfo =
	{
		Type: "PurchaseFurniture",
		FurnitureId: string,
	}
	| {
		Type: "PurchaseTheme",
		ThemeId: string,
	}
	| {
		Type: "SelectFurniture",
		FurnitureId: string?,
	}
	| {
		Type: "ApplyTheme",
		ThemeId: string,
	}
	| {
		Type: "Exit",
	}

export type Properties = RobloxComponents.FrameProperties & {
	SelectedFurnitureId: string?,
	AppliedThemeId: string?,
	PendingId: string?,
	Refusal: Refusal?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
local THEME_CATEGORY: Category = "Theme"
local CATEGORIES: { Category } = {}
for _, category: FurnitureCategory in FurnitureDefinition.listCategories() do
	table.insert(CATEGORIES, category)
end
table.insert(CATEGORIES, THEME_CATEGORY)
table.freeze(CATEGORIES)
-- how tall a counter is, in scale of the panel
local STRIP_SIZE = 0.075
-- how wide a card is + how far it is from one to the next, in scale of what the canvas is measured against
local CARD_SIZE = 0.375
local CARD_PITCH = 0.4
-- what's kept free around a card: the scroll bar below it + a gap above
local CARD_INSET = 35
local CARD_OFFSET = 5
local FURNITURE_TEXT = "Select"
local THEME_TEXT = "Apply"
local PURCHASING_TEXT = "Purchasing..."
local LABEL_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
-- the panel waits off the right edge of the screen, this far from where it belongs
local SLIDE_OFFSET = UDim2.fromScale(0.35, 0)
local SLIDE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function getButtonText(state: CardState, ownedText: string, price: number, currency: PseudoEnum.Currency): string
	if state == "ForSale" then
		return `{price} {currency}`
	elseif state == "Purchasing" then
		return PURCHASING_TEXT
	end
	return ownedText
end
-- Class
return function(props: Properties)
	local credits = React.useContext(SessionCreditsContext)
	local gems = React.useContext(SessionGemsContext)
	local inventory = React.useContext(SessionInventoryContext)
	local currentCategory: Category?, setCurrentCategory: (Category?) -> () = React.useState(nil :: Category?)
	local furnitureDefinitions = React.useMemo(function(): { FurnitureDefinition }
		if not currentCategory or currentCategory == THEME_CATEGORY then
			return table.freeze({})
		end
		return FurnitureDefinition.list(currentCategory :: FurnitureCategory)
	end, { currentCategory })
	local themeDefinitions = React.useMemo(function(): { ThemeDefinition }
		if currentCategory ~= THEME_CATEGORY then
			return table.freeze({})
		end
		return ThemeDefinition.list()
	end, { currentCategory })

	local openPosition = props.Position or UDim2.new()
	local frameRef, initialPosition, close = useSlide(
		openPosition,
		openPosition + SLIDE_OFFSET,
		SLIDE_TWEEN_INFO,
		function()
			props.OnAction({
				Type = "Exit",
			})
		end
	)

	local itemsRef: { current: ScrollingFrame? } = React.useRef(nil :: ScrollingFrame?)
	-- the cards of another category start over at the first one, however far the last ones were scrolled
	React.useEffect(function()
		local inst = itemsRef.current
		if inst then
			inst.CanvasPosition = Vector2.zero
		end
		return function() end
	end, { currentCategory })

	local refusal = props.Refusal
	-- a card is sized as a share of the canvas, which is never narrower than the list itself
	local canvasSize = math.max(1, (#furnitureDefinitions + #themeDefinitions) * CARD_PITCH)
	local cards: { [string]: React.ReactNode } = {}
	for i, definition in furnitureDefinitions do
		local isOwned = table.find(inventory.FurnitureIds, definition.Id) ~= nil
		local state: CardState = if props.SelectedFurnitureId == definition.Id
			then "Active"
			elseif isOwned then "Owned"
			elseif props.PendingId == definition.Id then "Purchasing"
			else "ForSale"
		cards[definition.Id] = e(
			ItemCard,
			{
				Position = UDim2.new(CARD_PITCH * (i - 1) / canvasSize, 0, 0, CARD_OFFSET),
				Size = UDim2.new(CARD_SIZE / canvasSize, 0, 1, -CARD_INSET),
				Title = definition.Name,
				ButtonText = getButtonText(state, FURNITURE_TEXT, definition.Price, definition.Currency),
				State = state,
				Refusal = if refusal and refusal.Id == definition.Id then refusal else nil,
				OnClick = function()
					if state == "ForSale" then
						props.OnAction({
							Type = "PurchaseFurniture",
							FurnitureId = definition.Id,
						})
					elseif state == "Owned" then
						props.OnAction({
							Type = "SelectFurniture",
							FurnitureId = definition.Id,
						})
					elseif state == "Active" then
						props.OnAction({
							Type = "SelectFurniture",
							FurnitureId = nil,
						})
					end
				end,
			} :: ItemCard.Properties,
			{
				Thumbnail = e(
					Thumbnail,
					{
						Size = UDim2.fromScale(1, 1),
						FurnitureId = definition.Id,
					} :: Thumbnail.Properties
				),
				-- the badge is drawn into the bottom right corner of its image, turned around it sits in the top left one
				Operational = definition.IsFunctional and e("ImageLabel", {
					BackgroundTransparency = 1,
					Image = Image.ui["gear-badge.png"],
					Rotation = 180,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 2,
				}),
			}
		)
	end
	for i, definition in themeDefinitions do
		local isOwned = table.find(inventory.ThemeIds, definition.Id) ~= nil
		local state: CardState = if isOwned
			then (if props.AppliedThemeId == definition.Id then "Active" else "Owned")
			elseif props.PendingId == definition.Id then "Purchasing"
			else "ForSale"
		cards[definition.Id] = e(
			ItemCard,
			{
				Position = UDim2.new(CARD_PITCH * (i - 1) / canvasSize, 0, 0, CARD_OFFSET),
				Size = UDim2.new(CARD_SIZE / canvasSize, 0, 1, -CARD_INSET),
				Title = definition.Name,
				ButtonText = getButtonText(state, THEME_TEXT, definition.Price, definition.Currency),
				State = state,
				Refusal = if refusal and refusal.Id == definition.Id then refusal else nil,
				OnClick = function()
					if state == "ForSale" then
						props.OnAction({
							Type = "PurchaseTheme",
							ThemeId = definition.Id,
						})
					elseif state == "Owned" or state == "Active" then
						props.OnAction({
							Type = "ApplyTheme",
							ThemeId = definition.Id,
						})
					end
				end,
			} :: ItemCard.Properties,
			{
				Swatch = e(
					ThemeSwatch,
					{
						Size = UDim2.fromScale(1, 1),
						ThemeDefinition = definition,
					} :: ThemeSwatch.Properties
				),
			}
		)
	end

	return e(RobloxComponents.Frame(
		{
			ref = frameRef,
			-- a click that lands on the panel isn't one on the base behind it
			Active = true,
			BackgroundColor3 = Color3.new(),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			Position = initialPosition,
		} :: RobloxComponents.FrameProperties,
		props,
		{
			CreditCount = e(
				BalanceCounter,
				{
					Active = true,
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.fromScale(1, -STRIP_SIZE),
					Size = UDim2.fromScale(1, STRIP_SIZE),
					Currency = PseudoEnum.Currency.Credits,
					Balance = credits,
				} :: BalanceCounter.Properties
			),
			GemCount = e(
				BalanceCounter,
				{
					Active = true,
					AnchorPoint = Vector2.new(1, 1),
					Position = UDim2.fromScale(1, 0),
					Size = UDim2.fromScale(1, STRIP_SIZE),
					Currency = PseudoEnum.Currency.Gems,
					Balance = gems,
				} :: BalanceCounter.Properties
			),
			Categories = e(
				CategoryList,
				{
					AnchorPoint = Vector2.new(0.5, 0),
					Position = UDim2.fromScale(0.5, 0.05),
					Size = UDim2.fromScale(0.8, 0.45),
					Categories = CATEGORIES,
					SelectedCategory = currentCategory,
					OnClick = function(category: Category)
						setCurrentCategory(category)
					end,
				} :: CategoryList.Properties
			),
			Refusal = refusal and e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0),
				BackgroundColor3 = Color3.fromRGB(151, 75, 75),
				BorderSizePixel = 0,
				FontFace = LABEL_FONT,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.8, 0.05),
				Text = refusal.Message,
				TextColor3 = Color3.new(1, 1, 1),
				TextScaled = true,
			}),
			Items = e(
				"ScrollingFrame",
				{
					ref = itemsRef,
					Active = true,
					AnchorPoint = Vector2.new(0.5, 0),
					BackgroundColor3 = Color3.new(),
					BackgroundTransparency = 0.4,
					BorderColor3 = Color3.new(1, 1, 1),
					CanvasSize = UDim2.fromScale(canvasSize, 0),
					Position = UDim2.fromScale(0.5, 0.55),
					ScrollBarThickness = 20,
					ScrollBarImageTransparency = if canvasSize > 1 then 0 else 1,
					ScrollingEnabled = canvasSize > 1,
					ScrollingDirection = Enum.ScrollingDirection.X,
					Size = UDim2.fromScale(0.8, 0.4),
				} :: RobloxComponents.ScrollingFrameProperties,
				{
					Cards = e(React.Fragment, {}, cards),
				}
			),
			Exit = e(
				ExitButton,
				{
					Position = UDim2.fromScale(0, 0),
					ZIndex = 2,
					[React.Event.Activated] = close,
				} :: ExitButton.Properties
			),
		}
	))
end
