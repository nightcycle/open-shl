--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
local Scene = require("@self/Scene")
-- Hooks
local useOpen = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/SuitManager/useOpen")
-- Contexts
local SessionActiveCharacterIdContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/ActiveCharacterId")
local SessionCharactersContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Characters")
local SessionEntitlementsContext =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Session/Entitlements")
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
local CharacterSelectTypes =
	require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/CharacterSelect/Types")
export type Character = SessionCharactersContext.Character
export type ActionInfo = CharacterSelectTypes.ActionInfo
export type Properties = CharacterSelectTypes.Properties
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
local UNNAMED_TEXT = "Unnamed Character"
local SELECT_TEXT = "SELECT"
local EDIT_TEXT = "EDIT"
-- what the old place said over its edit button, back when a save of it could get lost
local NOTE_TEXT = "Do not edit suits if you suspect data loss"
local OFFER_TEXT = "Get More Suit Slots!"
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- whoever was picked from the list, until then whoever is worn. a list that holds neither shows its first slot
local function getShown(characters: { Character }, pickedId: string?, activeCharacterId: string): Character?
	local out: Character? = characters[1]
	for _, character in characters do
		if character.Id == pickedId then
			return character
		elseif character.Id == activeCharacterId then
			out = character
		end
	end
	return out
end

local function row(props: {
	LayoutOrder: number,
	Text: string,
	IsSelected: boolean,
	OnClick: () -> (),
})
	local style = React.useContext(StyleContext)
	return e(
		"ImageButton",
		{
			BackgroundTransparency = 1,
			LayoutOrder = props.LayoutOrder,
			Size = CONSTANTS.ROW_SIZE,
			[React.Event.Activated] = props.OnClick,
		} :: RobloxComponents.ImageButtonProperties,
		{
			Art = e("ImageLabel", {
				BackgroundTransparency = 1,
				ImageColor3 = if props.IsSelected then style.Palette.Accent else CONSTANTS.ROW_COLOR,
				ImageContent = Content.fromUri(CONSTANTS.ROW_IMAGE),
				Position = CONSTANTS.ROW_ART_POSITION,
				Size = CONSTANTS.ROW_ART_SIZE,
			}),
			TextLabel = e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				-- it's a name somebody gave, not a word of the game
				AutoLocalize = false,
				BackgroundTransparency = 1,
				FontFace = style.Fonts.Body,
				Position = UDim2.fromScale(0.5, 0.5),
				Size = CONSTANTS.ROW_TEXT_SIZE,
				Text = props.Text,
				TextColor3 = if props.IsSelected then style.Palette.TextOnAccent else CONSTANTS.ROW_TEXT_COLOR,
				TextScaled = true,
				TextWrapped = true,
				ZIndex = 2,
			}),
		}
	)
end

local function list(props: {
	children: { [string]: React.ReactNode }?,
})
	local style = React.useContext(StyleContext)
	local ref, initialSize = useOpen(CONSTANTS.LIST_SIZE, style.Motion.Open, CONSTANTS.PANEL_DELAY)
	return e("ImageLabel", {
		ref = ref,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		ImageContent = Content.fromUri(CONSTANTS.LIST_IMAGE),
		Position = CONSTANTS.LIST_POSITION,
		Size = initialSize,
	}, {
		UIListLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = CONSTANTS.LIST_PADDING,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
		}),
		Rows = e(React.Fragment, {}, props.children),
	})
end

-- a button that's nothing but its art: what's pressed is as wide as the art + as tall as the bar that's drawn on it
local function tagButton(props: {
	AnchorPoint: Vector2,
	Position: UDim2,
	Image: string,
	Text: string,
	OnClick: (() -> ())?,
	children: { [string]: React.ReactNode }?,
})
	local style = React.useContext(StyleContext)
	local ref, initialSize = useOpen(CONSTANTS.BUTTON_SIZE, style.Motion.Open)
	return e(
		"ImageButton",
		{
			ref = ref,
			AnchorPoint = props.AnchorPoint,
			BackgroundTransparency = 1,
			Modal = true,
			Position = props.Position,
			Size = initialSize,
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			[React.Event.Activated] = props.OnClick,
		} :: RobloxComponents.ImageButtonProperties,
		{
			Art = e("ImageLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ImageContent = Content.fromUri(props.Image),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(1, 1),
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}),
			Tag = e("TextLabel", {
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = style.Palette.Field,
				BorderSizePixel = 0,
				FontFace = style.Fonts.Heading,
				Position = CONSTANTS.TAG_POSITION,
				Size = CONSTANTS.TAG_SIZE,
				Text = props.Text,
				TextColor3 = style.Palette.Accent,
				TextScaled = true,
				TextWrapped = true,
				ZIndex = 2,
			}),
			Children = e(React.Fragment, {}, props.children),
		}
	)
end

local function slotOffer(props: {
	OnClick: () -> (),
})
	local style = React.useContext(StyleContext)
	local ref, initialSize = useOpen(CONSTANTS.OFFER_SIZE, style.Motion.Open, CONSTANTS.PANEL_DELAY)
	return e("ImageLabel", {
		ref = ref,
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundTransparency = 1,
		ImageContent = Content.fromUri(CONSTANTS.OFFER_IMAGE),
		Position = CONSTANTS.OFFER_POSITION,
		Size = initialSize,
		SizeConstraint = Enum.SizeConstraint.RelativeXX,
	}, {
		Icon = e(
			"ImageButton",
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = CONSTANTS.OFFER_ICON_COLOR,
				BorderSizePixel = 0,
				ImageContent = Content.fromUri(CONSTANTS.OFFER_ICON_IMAGE),
				Position = CONSTANTS.OFFER_ICON_POSITION,
				Size = CONSTANTS.OFFER_ICON_SIZE,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				[React.Event.Activated] = props.OnClick,
			} :: RobloxComponents.ImageButtonProperties
		),
		Button = e(
			"ImageButton",
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				ImageContent = Content.fromUri(CONSTANTS.ROW_IMAGE),
				Position = CONSTANTS.OFFER_BUTTON_POSITION,
				Size = CONSTANTS.OFFER_BUTTON_SIZE,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
				-- its art reaches up over the foot of the icon
				ZIndex = 2,
				[React.Event.Activated] = props.OnClick,
			} :: RobloxComponents.ImageButtonProperties,
			{
				TextLabel = e("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					FontFace = style.Fonts.Heading,
					Position = CONSTANTS.OFFER_TEXT_POSITION,
					Size = CONSTANTS.OFFER_TEXT_SIZE,
					Text = OFFER_TEXT,
					TextColor3 = style.Palette.Accent,
					TextScaled = true,
					TextWrapped = true,
				}),
			}
		),
	})
end
-- Class
-- the character select as a list: every slot is a row on the left, whoever is picked stands on the stage in the
-- middle + is worn or edited from the two buttons under it. there's no way out but one of those two
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local characters = React.useContext(SessionCharactersContext)
	local activeCharacterId = React.useContext(SessionActiveCharacterIdContext)
	local entitlements = React.useContext(SessionEntitlementsContext)

	local pickedId: string?, setPickedId: (string?) -> () = React.useState(nil :: string?)
	local character = getShown(characters, pickedId, activeCharacterId)

	local rows: { [string]: React.ReactNode } = {}
	for i, other in characters do
		-- a hero is listed by the name it fights under
		local name = other.Identities.Main.Profile.Name
		rows[`Row-{i}`] = e(row, {
			LayoutOrder = i,
			Text = if name == "" then UNNAMED_TEXT else name,
			IsSelected = other == character,
			OnClick = function()
				setPickedId(other.Id)
			end,
		})
	end

	local errorMessage = props.ErrorMessage
	local function buySlots()
		props.OnAction({
			Type = "BuySlots",
		})
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			Backdrop = e("Frame", {
				Active = true,
				BackgroundColor3 = Color3.new(),
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, -1),
				Size = UDim2.fromScale(1, 2),
				ZIndex = -1,
			}),
			Scene = e(
				Scene,
				{
					Appearance = if character then character.Identities.Main.Appearance else nil,
				} :: Scene.Properties
			),
			List = e(list, {}, rows),
			Select = e(tagButton, {
				AnchorPoint = Vector2.new(1, 1),
				Position = CONSTANTS.SELECT_POSITION,
				Image = CONSTANTS.SELECT_IMAGE,
				Text = SELECT_TEXT,
				OnClick = if character
					then function()
						props.OnAction({
							Type = "Select",
							CharacterId = character.Id,
						})
					end
					else nil,
			}),
			Edit = e(tagButton, {
				AnchorPoint = Vector2.new(0, 1),
				Position = CONSTANTS.EDIT_POSITION,
				Image = CONSTANTS.EDIT_IMAGE,
				Text = EDIT_TEXT,
				OnClick = if character
					then function()
						props.OnAction({
							Type = "Edit",
							CharacterId = character.Id,
						})
					end
					else nil,
			}, {
				-- the one line of the menu that isn't art, so it's where a refusal is read as well
				Note = e("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 1),
					BackgroundTransparency = 1,
					FontFace = style.Fonts.Note,
					Position = UDim2.fromScale(0.5, 0),
					Size = CONSTANTS.NOTE_SIZE,
					Text = errorMessage or NOTE_TEXT,
					TextColor3 = if errorMessage then style.Palette.Warning else CONSTANTS.NOTE_COLOR,
					TextSize = style.TextSizes.Note,
					ZIndex = 2,
				}),
			}),
			-- whoever has the pass is never asked again
			Offer = table.find(entitlements, "ExtraCharacterSlots") == nil and e(slotOffer, {
				OnClick = buySlots,
			}),
		}
	))
end
