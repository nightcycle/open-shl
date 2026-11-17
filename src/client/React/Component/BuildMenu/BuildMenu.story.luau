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
local BaseConstructor = require("@game/ReplicatedStorage/Shared/Constructor/Base")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local FurnitureDefinition = require("@game/ReplicatedStorage/Shared/Definition/Furniture")
local ProductDefinition = require("@game/ReplicatedStorage/Shared/Definition/Product")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
local ThemeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Theme")
-- Components
local ParentComponent = require(".")
-- Hooks
-- Contexts
local SessionCreditsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Credits")
local SessionGemsContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Gems")
local SessionInventoryContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Inventory")
-- Types
type BaseInventory = SessionInventoryContext.BaseInventory
type Refusal = ParentComponent.Refusal
-- Constants
-- enough to buy some of what the menu sells, the rest shows what a refusal looks like
local STARTING_CREDITS = 12_000
local STARTING_GEMS = 100
local PURCHASE_DURATION = 1
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
	local credits, setCredits = React.useState(STARTING_CREDITS)
	local gems, setGems = React.useState(STARTING_GEMS)
	local inventory: BaseInventory, setInventory: (BaseInventory) -> () = React.useState(BaseConstructor.newInventory())
	local selectedFurnitureId: string?, setSelectedFurnitureId: (string?) -> () = React.useState(nil :: string?)
	local appliedThemeId, setAppliedThemeId = React.useState(ThemeDefinition.DEFAULT_ID)
	local pendingId: string?, setPendingId: (string?) -> () = React.useState(nil :: string?)
	local refusal: Refusal?, setRefusal: (Refusal?) -> () = React.useState(nil :: Refusal?)
	local isMountedRef = React.useRef(true)
	React.useEffect(function()
		isMountedRef.current = true
		return function()
			isMountedRef.current = false
		end
	end, {})

	-- the price is taken + the thing handed out after a moment, the way the server does it
	local function purchase(
		id: string,
		name: string,
		price: number,
		currency: PseudoEnum.Currency,
		isFurniture: boolean
	)
		if pendingId then
			return
		end
		setRefusal(nil)
		setPendingId(id)
		task.delay(PURCHASE_DURATION, function()
			if not isMountedRef.current then
				return
			end
			setPendingId(nil)
			local balance = if currency == PseudoEnum.Currency.Credits then credits else gems
			if balance < price then
				setRefusal({
					Message = `not enough {ProductDefinition.getCurrencyName(currency)}`,
					Id = id,
				})
				return
			end
			if table.find(inventory.FurnitureIds, id) or table.find(inventory.ThemeIds, id) then
				setRefusal({
					Message = `"{name}" is already owned`,
					Id = id,
				})
				return
			end
			if currency == PseudoEnum.Currency.Credits then
				setCredits(credits - price)
			else
				setGems(gems - price)
			end
			setInventory(FreezeUtil.delta(inventory, function(t)
				table.insert(if isFurniture then t.FurnitureIds else t.ThemeIds, id)
				return t
			end))
		end)
	end

	return e(SessionCreditsContext.Provider, {
		value = credits,
	}, {
		Gems = e(SessionGemsContext.Provider, {
			value = gems,
		}, {
			Inventory = e(SessionInventoryContext.Provider, {
				value = inventory,
			}, {
				Frame = e("Frame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = UDim2.fromScale(0.5, 0.5),
					Size = UDim2.fromScale(1, 1),
				}, {
					-- stands in for the build button of the hud
					Open = e(
						"TextButton",
						{
							AnchorPoint = Vector2.new(0.5, 0.5),
							BackgroundColor3 = Color3.fromRGB(135, 0, 203),
							BorderColor3 = Color3.fromRGB(27, 42, 53),
							FontFace = Font.new("rbxasset://fonts/families/SourceSansPro.json"),
							Position = UDim2.fromScale(0.1, 0.75),
							Size = UDim2.fromScale(0.08, 0.08),
							SizeConstraint = Enum.SizeConstraint.RelativeYY,
							Text = isOpen and "Close" or "Open",
							TextColor3 = Color3.new(1, 1, 1),
							TextScaled = true,
							[React.Event.Activated] = function()
								setRefusal(nil)
								setSelectedFurnitureId(nil)
								setIsOpen(not isOpen)
							end,
						} :: RobloxComponents.TextButtonProperties
					),
					Menu = isOpen and e(
						ParentComponent,
						{
							AnchorPoint = Vector2.new(1, 0.5),
							Position = UDim2.fromScale(1, 0.55),
							Size = UDim2.fromScale(0.3, 0.8),
							SelectedFurnitureId = selectedFurnitureId,
							AppliedThemeId = appliedThemeId,
							PendingId = pendingId,
							Refusal = refusal,
							OnAction = function(action: ParentComponent.ActionInfo)
								if action.Type == "PurchaseFurniture" then
									local definitionRes = FurnitureDefinition.get(action.FurnitureId)
									if definitionRes.IsErr then
										setRefusal({
											Message = definitionRes.Value,
										})
										return
									end
									local definition = definitionRes.Value
									purchase(
										definition.Id,
										definition.Name,
										definition.Price,
										definition.Currency,
										true
									)
								elseif action.Type == "PurchaseTheme" then
									local definitionRes = ThemeDefinition.get(action.ThemeId)
									if definitionRes.IsErr then
										setRefusal({
											Message = definitionRes.Value,
										})
										return
									end
									local definition = definitionRes.Value
									purchase(
										definition.Id,
										definition.Name,
										definition.Price,
										definition.Currency,
										false
									)
								elseif action.Type == "SelectFurniture" then
									setRefusal(nil)
									setSelectedFurnitureId(action.FurnitureId)
								elseif action.Type == "ApplyTheme" then
									setRefusal(nil)
									setAppliedThemeId(action.ThemeId)
								elseif action.Type == "Exit" then
									setRefusal(nil)
									setSelectedFurnitureId(nil)
									setIsOpen(false)
								end
							end,
							SizeConstraint = Enum.SizeConstraint.RelativeXY,
						} :: ParentComponent.Properties
					),
				}),
			}),
		}),
	})
end)
