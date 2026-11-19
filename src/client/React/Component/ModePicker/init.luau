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
local ModeSelectTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ModeSelect/Types")
export type Mode = ModeSelectTypes.Mode
export type ActionInfo = ModeSelectTypes.ActionInfo
export type Properties = ModeSelectTypes.Properties
type CardInfo = {
	Mode: Mode,
	Icon: string,
	Title: string,
	Perks: { string },
}
-- Constants
-- left to right
local CARDS: { CardInfo } = table.freeze({
	table.freeze({
		Mode = "roleplay" :: Mode,
		Icon = Image["shl-3"].ui.intro["roleplay-icon.png"],
		Title = "Roleplay Mode",
		Perks = table.freeze({ "- PVP Disabled", "- No Disaster Events", "- Social Focused" }),
	}),
	table.freeze({
		Mode = "combat" :: Mode,
		Icon = Image["shl-3"].ui.intro["combat-icon.png"],
		Title = "Combat Mode",
		Perks = table.freeze({ "- PVP Enabled", "- Disaster Events", "- Action Focused" }),
	}),
})
local PLAY_TEXT = "Play"
-- what the card that was picked says for as long as the player is on the way to its place
local LEAVING_TITLE = "Teleporting.."
-- a card is a column this wide in scale of the height of the screen, everything in it is sized off that width
local CARD_WIDTH = 0.4
-- how far the cards are apart in scale of the width of the screen
local CARD_PADDING = 0.1
-- how far the rows of a column are apart in scale of its height
local ROW_PADDING = 0.02
local TITLE_HEIGHT = 0.25
local PERKS_HEIGHT = 0.5
local PERK_HEIGHT = 0.125
local PLAY_SIZE = UDim2.fromScale(0.8, 0.2)
-- neither of the two is a color of the palette
local TITLE_COLOR = Color3.new()
local PLAY_COLOR = Color3.fromRGB(0, 154, 220)
-- Variables
-- References
-- Private Functions
local e = React.createElement

local function card(
	props: {
		Info: CardInfo,
		LayoutOrder: number,
		IsClickable: boolean,
		-- the player is on the way to its place: all that's left of it is the picture over the line that says so
		IsLeaving: boolean,
		OnClick: () -> (),
	}
)
	local style = React.useContext(StyleContext)
	local info = props.Info

	local perks: { [string]: React.ReactNode } = {}
	for i, perk in info.Perks do
		perks[`Perk{i}`] = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Body,
			LayoutOrder = i,
			Size = UDim2.fromScale(1, PERK_HEIGHT),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			Text = perk,
			TextColor3 = style.Palette.Text,
			TextScaled = true,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	return e(
		"Frame",
		{
			BackgroundTransparency = 1,
			LayoutOrder = props.LayoutOrder,
			Size = UDim2.fromScale(CARD_WIDTH, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
		} :: RobloxComponents.FrameProperties,
		{
			UIListLayout = e("UIListLayout", {
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(ROW_PADDING, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
				VerticalAlignment = Enum.VerticalAlignment.Center,
			}),

			Icon = e("ImageLabel", {
				BackgroundTransparency = 1,
				ImageContent = Content.fromUri(info.Icon),
				LayoutOrder = 1,
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),

			Title = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = style.Fonts.Body,
				LayoutOrder = 2,
				Size = UDim2.fromScale(1, TITLE_HEIGHT),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				Text = if props.IsLeaving then LEAVING_TITLE else info.Title,
				TextColor3 = TITLE_COLOR,
				TextScaled = true,
				TextWrapped = true,
			}),

			Perks = e(
				"Frame",
				{
					BackgroundTransparency = 1,
					LayoutOrder = 3,
					Size = UDim2.fromScale(1, PERKS_HEIGHT),
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Visible = not props.IsLeaving,
				} :: RobloxComponents.FrameProperties,
				{
					UIListLayout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Vertical,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						Padding = UDim.new(ROW_PADDING, 0),
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					Perks = e(React.Fragment, {}, perks),
				}
			),

			Play = e(
				"TextButton",
				{
					Active = props.IsClickable,
					AutoButtonColor = props.IsClickable,
					BackgroundColor3 = PLAY_COLOR,
					FontFace = style.Fonts.Body,
					LayoutOrder = 4,
					Selectable = props.IsClickable,
					Size = PLAY_SIZE,
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					Text = PLAY_TEXT,
					TextColor3 = style.Palette.TextOnAccent,
					TextScaled = true,
					TextWrapped = true,
					Visible = not props.IsLeaving,
					[React.Event.Activated] = props.IsClickable and function()
						props.OnClick()
					end or nil,
				} :: RobloxComponents.TextButtonProperties,
				{
					-- a pill
					UICorner = e("UICorner", {
						CornerRadius = UDim.new(1, 0),
					}),
				}
			),
		}
	)
end
-- Class
-- the two modes as cards side by side on a blank screen. it has no servers to browse + no id box, so it's never
-- handed an answer about an id + reports neither
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	-- the card whose button was pressed last, it's the one that's left while the player is leaving
	local pressedMode: Mode?, setPressedMode: (Mode?) -> () = React.useState(nil :: Mode?)
	local leavingMode: Mode? = if props.IsLeaving then pressedMode else nil
	local isClickable = not props.IsLeaving

	local cards: { [string]: React.ReactNode } = {}
	for i, info in CARDS do
		-- the cards that weren't picked are gone until the choice falls through
		if leavingMode and leavingMode ~= info.Mode then
			continue
		end
		cards[info.Mode] = e(card, {
			Info = info,
			LayoutOrder = i,
			IsClickable = isClickable,
			IsLeaving = leavingMode == info.Mode,
			OnClick = function()
				setPressedMode(info.Mode)
				props.OnAction({
					Type = "ModePressed",
					Mode = info.Mode,
				})
			end,
		})
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			-- covers the top bar inset
			Backdrop = e("Frame", {
				Active = true,
				BackgroundColor3 = style.Palette.Field,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, -1),
				Size = UDim2.fromScale(1, 2),
			}),

			Cards = e(
				"Frame",
				{
					BackgroundTransparency = 1,
					Size = UDim2.fromScale(1, 1),
					ZIndex = 2,
				} :: RobloxComponents.FrameProperties,
				{
					UIListLayout = e("UIListLayout", {
						FillDirection = Enum.FillDirection.Horizontal,
						HorizontalAlignment = Enum.HorizontalAlignment.Center,
						Padding = UDim.new(CARD_PADDING, 0),
						SortOrder = Enum.SortOrder.LayoutOrder,
						VerticalAlignment = Enum.VerticalAlignment.Center,
					}),
					Cards = e(React.Fragment, {}, cards),
				}
			),

			-- the place it was made for never said why a choice fell through, the line sits under the cards
			Notice = props.Notice and e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				FontFace = style.Fonts.Body,
				Position = UDim2.fromScale(0.5, 0.99),
				Size = UDim2.fromScale(0.8, 0.05),
				Text = props.Notice,
				TextColor3 = style.Palette.Negative,
				TextScaled = true,
				TextWrapped = true,
				ZIndex = 3,
			}),
		}
	))
end
