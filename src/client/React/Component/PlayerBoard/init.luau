--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
local ExitButton = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/ExitButton")
-- Hooks
local useSlide = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/useSlide")
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
-- somebody in the game
export type Row = {
	UserId: number,
	UserName: string,
	-- who they walk about as. left out, nobody knows
	Name: string?,
	-- what's paid for taking them down. left out, their cell stays empty
	Bounty: number?,
}
export type ActionInfo = {
	Type: "Exit",
}
export type Properties = RobloxComponents.FrameProperties & {
	-- in the order they're listed in
	Rows: { Row },
	OnAction: (ActionInfo) -> (),
}
-- Constants
local CONSTANTS = require("@self/CONSTANTS")
local TITLE_TEXT = "INFORMATION"
local USER_NAME_TEXT = "USERNAME"
-- what the old place had over the bounties, the art under it says what they are
local BOUNTY_TEXT = "PROPERTIES"
local NAME_TEXT = "NAME"
local UNKNOWN_TEXT = "Unknown"
-- the panel comes down from over the screen
local SLIDE_OFFSET = UDim2.fromScale(0, 1)
-- Variables
-- References
-- Private Functions
local e = React.createElement

-- a word of the art is covered by a box that says it again, or says something else
local function tag(props: {
	Position: UDim2,
	Size: UDim2,
	Text: string,
	BackgroundColor3: Color3,
})
	local style = React.useContext(StyleContext)
	return e("TextLabel", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = props.BackgroundColor3,
		BorderSizePixel = 0,
		FontFace = style.Fonts.Heading,
		Position = props.Position,
		Size = props.Size,
		Text = props.Text,
		TextColor3 = style.Palette.Accent,
		TextScaled = true,
		TextWrapped = true,
		ZIndex = 4,
	})
end

local function cell(props: {
	LayoutOrder: number,
	Size: UDim2,
	Text: string,
})
	local style = React.useContext(StyleContext)
	return e("Frame", {
		BackgroundColor3 = style.Palette.FieldAlt,
		BorderSizePixel = 0,
		LayoutOrder = props.LayoutOrder,
		Size = props.Size,
	}, {
		TextLabel = e("TextLabel", {
			-- it's a name somebody has or gave, not a word of the game
			AutoLocalize = false,
			BackgroundTransparency = 1,
			FontFace = style.Fonts.Body,
			Size = UDim2.fromScale(1, 1),
			Text = props.Text,
			TextColor3 = CONSTANTS.ROW_TEXT_COLOR,
			TextScaled = true,
			TextWrapped = true,
		}),
	})
end

local function row(props: {
	LayoutOrder: number,
	Row: Row,
})
	local bounty = props.Row.Bounty
	return e("Frame", {
		BackgroundTransparency = 1,
		LayoutOrder = props.LayoutOrder,
		Size = CONSTANTS.ROW_SIZE,
	}, {
		UIListLayout = e("UIListLayout", {
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			Padding = CONSTANTS.ROW_PADDING,
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Top,
		}),
		UserName = e(cell, {
			LayoutOrder = 1,
			Size = CONSTANTS.USER_NAME_CELL_SIZE,
			Text = props.Row.UserName,
		}),
		Bounty = e(cell, {
			LayoutOrder = 2,
			Size = CONSTANTS.BOUNTY_CELL_SIZE,
			Text = if bounty then `${bounty}` else "",
		}),
		Name = e(cell, {
			LayoutOrder = 3,
			Size = CONSTANTS.NAME_CELL_SIZE,
			Text = props.Row.Name or UNKNOWN_TEXT,
		}),
	})
end
-- Class
-- the player list of the legacy place: one panel in the middle of the screen with a row for everybody in the game,
-- what roblox knows them as on the left of it + who they walk about as on the right
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local scrollBarThickness: number, setScrollBarThickness: (number) -> () =
		React.useState(CONSTANTS.SCROLL_BAR_THICKNESS)
	local function measure(menu: Frame)
		setScrollBarThickness(math.round(menu.AbsoluteSize.Y * CONSTANTS.SCROLL_BAR_SCALE))
	end

	local openPosition = props.Position or UDim2.new()
	local frameRef, initialPosition, close = useSlide(
		openPosition,
		openPosition - SLIDE_OFFSET,
		style.Motion.Slide,
		function()
			props.OnAction({
				Type = "Exit",
			})
		end
	)

	local rows: { [string]: React.ReactNode } = {}
	for i, rowInfo in props.Rows do
		rows[`Row-{rowInfo.UserId}`] = e(row, {
			LayoutOrder = i,
			Row = rowInfo,
		})
	end

	return e(RobloxComponents.Frame(
		{
			ref = frameRef,
			Active = false,
			BackgroundTransparency = 1,
			Position = initialPosition,
		} :: RobloxComponents.FrameProperties,
		props,
		{
			Menu = e(
				"Frame",
				{
					-- a click that lands on the panel isn't one on the world behind it
					Active = true,
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundTransparency = 1,
					Position = CONSTANTS.MENU_POSITION,
					Size = CONSTANTS.MENU_SIZE,
					SizeConstraint = Enum.SizeConstraint.RelativeXX,
					[React.Change.AbsoluteSize] = measure,
				} :: RobloxComponents.FrameProperties,
				{
					Track = e("ImageLabel", {
						BackgroundTransparency = 1,
						ImageContent = Content.fromUri(CONSTANTS.TRACK_IMAGE),
						Position = CONSTANTS.TRACK_POSITION,
						Size = CONSTANTS.TRACK_SIZE,
					}),
					Art = e("ImageLabel", {
						BackgroundTransparency = 1,
						ImageContent = Content.fromUri(CONSTANTS.MENU_IMAGE),
						Size = UDim2.fromScale(1, 1),
						ZIndex = 2,
					}),
					Cover = e("Frame", {
						BackgroundColor3 = style.Palette.Field,
						BorderSizePixel = 0,
						Position = CONSTANTS.COVER_POSITION,
						Size = CONSTANTS.COVER_SIZE,
						ZIndex = 3,
					}),
					Title = e(tag, {
						Position = CONSTANTS.TITLE_POSITION,
						Size = CONSTANTS.TITLE_SIZE,
						Text = TITLE_TEXT,
						BackgroundColor3 = style.Palette.Field,
					}),
					UserNameHead = e(tag, {
						Position = CONSTANTS.USER_NAME_HEAD_POSITION,
						Size = CONSTANTS.USER_NAME_HEAD_SIZE,
						Text = USER_NAME_TEXT,
						BackgroundColor3 = CONSTANTS.HEAD_COLOR,
					}),
					BountyHead = e(tag, {
						Position = CONSTANTS.BOUNTY_HEAD_POSITION,
						Size = CONSTANTS.BOUNTY_HEAD_SIZE,
						Text = BOUNTY_TEXT,
						BackgroundColor3 = CONSTANTS.HEAD_COLOR,
					}),
					NameHead = e(tag, {
						Position = CONSTANTS.NAME_HEAD_POSITION,
						Size = CONSTANTS.NAME_HEAD_SIZE,
						Text = NAME_TEXT,
						BackgroundColor3 = CONSTANTS.HEAD_COLOR,
					}),
					List = e(
						"ScrollingFrame",
						{
							AnchorPoint = Vector2.new(0.5, 1),
							BackgroundTransparency = 1,
							BorderSizePixel = 0,
							BottomImage = "",
							CanvasSize = CONSTANTS.LIST_CANVAS_SIZE,
							MidImage = CONSTANTS.SCROLL_BAR_IMAGE,
							Position = CONSTANTS.LIST_POSITION,
							-- the engine starts a scroll bar out black
							ScrollBarImageColor3 = Color3.new(1, 1, 1),
							ScrollBarThickness = scrollBarThickness,
							Size = CONSTANTS.LIST_SIZE,
							TopImage = "",
							VerticalScrollBarPosition = Enum.VerticalScrollBarPosition.Left,
							ZIndex = 4,
						} :: RobloxComponents.ScrollingFrameProperties,
						{
							UIListLayout = e("UIListLayout", {
								FillDirection = Enum.FillDirection.Vertical,
								HorizontalAlignment = Enum.HorizontalAlignment.Center,
								Padding = CONSTANTS.LIST_PADDING,
								SortOrder = Enum.SortOrder.LayoutOrder,
								VerticalAlignment = Enum.VerticalAlignment.Top,
							}),
							Rows = e(React.Fragment, {}, rows),
						}
					),
					Exit = e(
						ExitButton,
						{
							Position = CONSTANTS.EXIT_POSITION,
							ZIndex = 5,
							[React.Event.Activated] = close,
						} :: ExitButton.Properties
					),
				}
			),
		}
	))
end
