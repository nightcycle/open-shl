--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Components
-- Hooks
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local ServerType = require("@game/ReplicatedStorage/Shared/Type/Server")
type Mode = ServerType.Mode
-- a place of the game somebody can go over to
export type CardInfo = {
	Mode: Mode,
	Title: string,
	Description: string,
	-- the teleport was asked for: the card says so + has no button until it's handed in without this again
	IsLeaving: boolean?,
	-- why the last try went nowhere, read in place of the description
	Notice: string?,
}
export type ActionInfo =
	{
		Type: "Teleport", -- the button of a card was pressed
		Mode: Mode,
	}
	| {
		Type: "Exit",
	}
export type Properties = RobloxComponents.FrameProperties & {
	Cards: { CardInfo },
	OnAction: (ActionInfo) -> (),
}
-- Constants
local ART = Image["shl-3"].ui["mode-changer"]
-- what a card reads once its button was pressed, as the old place had it
local LEAVING_TITLE_TEXT = "Teleporting.."
local LEAVING_DESCRIPTION_TEXT = "You should teleport shortly. If not that's due to Roblox server issues."
local BUTTON_TEXT = "TELEPORT"
-- the picture of the panel is a square of this much of the height of the screen
local MENU_SIZE = UDim2.fromScale(0.75, 0.75)
local EXIT_SIZE = UDim2.fromOffset(31, 31)
local EXIT_POSITION = UDim2.fromScale(0.7702, 0.0651)
local SIDEBAR_SIZE = UDim2.fromScale(1.2388, 0.9469)
local SIDEBAR_POSITION = UDim2.fromScale(-0.425, 0.053)
local LIST_SIZE = UDim2.fromScale(0.571, 0.852)
local LIST_POSITION = UDim2.fromScale(0.469, 0.5322)
-- four times as tall as what's seen of it, however few cards there are
local LIST_CANVAS_SIZE = UDim2.fromScale(0, 4)
local LIST_PADDING = UDim.new(0, 5)
local LIST_TOP_PADDING = UDim.new(0.0025, 0)
-- how much of the width of the list its bar takes up, on its left
local SCROLL_BAR_SCALE = 0.05
-- a card is this much of the width of the list wide + of that width tall
local CARD_SIZE = UDim2.fromScale(0.85, 0.56)
local CARD_COLOR3 = Color3.fromRGB(236, 236, 236)
local CARD_ART_POSITION = UDim2.fromScale(0.5, 0.345)
local PICTURE_SIZE = UDim2.fromScale(0.55, 0.55)
local PICTURE_POSITION = UDim2.fromScale(0.225, 0.335)
local TITLE_SIZE = UDim2.fromScale(0.461, 0.167)
local TITLE_POSITION = UDim2.fromScale(0.7174, 0.0471)
local DESCRIPTION_SIZE = UDim2.fromScale(0.4364, 0.414)
local DESCRIPTION_POSITION = UDim2.fromScale(0.7214, 0.2295)
local BUTTON_SIZE = UDim2.new(1, -14, 0.2, 0)
local BUTTON_POSITION = UDim2.fromScale(0.5, 0.75)
local TAG_SIZE = UDim2.fromScale(0.6, 1)
-- shades off the ones every other panel of the look has
local TEXT_COLOR3 = Color3.fromRGB(57, 57, 57)
local TAG_COLOR3 = Color3.fromRGB(19, 160, 222)
local TAG_TEXT_COLOR3 = Color3.fromRGB(254, 254, 254)
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function card(props: {
	CardInfo: CardInfo,
	LayoutOrder: number,
	OnPress: () -> (),
})
	local style = React.useContext(StyleContext)
	local cardInfo = props.CardInfo
	local isLeaving = cardInfo.IsLeaving == true

	return e("Frame", {
		BackgroundColor3 = CARD_COLOR3,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		Size = CARD_SIZE,
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
	}, {
		Art = e("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			ImageContent = Content.fromUri(ART["card.png"]),
			Position = CARD_ART_POSITION,
			Size = UDim2.fromScale(1, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
		}),
		Picture = e("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Color3.new(1, 1, 1),
			ImageContent = Content.fromUri(ART["mode-image.png"]),
			Position = PICTURE_POSITION,
			Size = PICTURE_SIZE,
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			ZIndex = 2,
		}),
		Title = e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Body,
			Position = TITLE_POSITION,
			Size = TITLE_SIZE,
			Text = if isLeaving then LEAVING_TITLE_TEXT else cardInfo.Title,
			TextColor3 = TEXT_COLOR3,
			TextScaled = true,
			TextWrapped = true,
			ZIndex = 2,
		}),
		Description = e("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Body,
			Position = DESCRIPTION_POSITION,
			Size = DESCRIPTION_SIZE,
			Text = if isLeaving then LEAVING_DESCRIPTION_TEXT else cardInfo.Notice or cardInfo.Description,
			TextColor3 = TEXT_COLOR3,
			TextScaled = true,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			ZIndex = 2,
		}),
		-- the old place hid it once it was pressed, there's nothing more to ask of a card that's leaving
		Button = not isLeaving and e("ImageButton", {
			AnchorPoint = Vector2.new(0.5, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Position = BUTTON_POSITION,
			Size = BUTTON_SIZE,
			ZIndex = 2,
			[React.Event.Activated] = props.OnPress,
		}, {
			Art = e("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ImageContent = Content.fromUri(ART["teleport-button.png"]),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				ZIndex = 2,
			}),
			Tag = e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = TAG_COLOR3,
				BorderSizePixel = 0,
				FontFace = style.Fonts.Heading,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = TAG_SIZE,
				Text = BUTTON_TEXT,
				TextColor3 = TAG_TEXT_COLOR3,
				TextScaled = true,
				TextWrapped = true,
				ZIndex = 3,
			}),
		}),
	})
end
-- Class
-- the panel of the legacy place that leads to its other places: a list of cards, one for each, with a button that
-- sends the player there. it's there or it isn't, nothing of it slides. a list without a card is an empty panel
return function(props: Properties): React.ReactNode
	-- the bar of the list is as thick as a share of its width, which is only known once it's on a screen
	local barThickness, setBarThickness = React.useState(0)

	local cards: { [string]: React.ReactNode } = {}
	for index, cardInfo in props.Cards do
		cards[cardInfo.Mode] = e(card, {
			CardInfo = cardInfo,
			LayoutOrder = index,
			OnPress = function()
				props.OnAction({
					Type = "Teleport",
					Mode = cardInfo.Mode,
				})
			end,
		})
	end

	return e(RobloxComponents.Frame(
		{
			Active = false,
			BackgroundTransparency = 1,
		},
		props,
		{
			Menu = e("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ImageContent = Content.fromUri(ART["panel.png"]),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = MENU_SIZE,
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
			}, {
				Sidebar = e("ImageLabel", {
					BackgroundTransparency = 1,
					ImageContent = Content.fromUri(Image["shl-3"].ui.common["sidebar-thin.png"]),
					Position = SIDEBAR_POSITION,
					Size = SIDEBAR_SIZE,
				}),
				Exit = e("ImageButton", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					ImageContent = Content.fromUri(Image.core.ui["exit.png"]),
					Position = EXIT_POSITION,
					Size = EXIT_SIZE,
					ZIndex = 10,
					[React.Event.Activated] = function()
						props.OnAction({
							Type = "Exit",
						})
					end,
				}),
				List = e("ScrollingFrame", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					CanvasSize = LIST_CANVAS_SIZE,
					Position = LIST_POSITION,
					ScrollBarThickness = barThickness,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					Size = LIST_SIZE,
					VerticalScrollBarInset = Enum.ScrollBarInset.Always,
					VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left,
					ZIndex = 20,
					[React.Change.AbsoluteSize] = function(list: ScrollingFrame)
						setBarThickness(math.round(list.AbsoluteSize.X * SCROLL_BAR_SCALE))
					end,
				}, {
					UIListLayout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Right,
						Padding = LIST_PADDING,
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Top,
					}),
					UIPadding = e("UIPadding", {
						PaddingTop = LIST_TOP_PADDING,
					}),
					Cards = e(React.Fragment, {}, cards),
				}),
			}),
		}
	))
end
