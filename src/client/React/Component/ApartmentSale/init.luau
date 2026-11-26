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
local StyleTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Types")
type Area = StyleTypes.Area
-- one kind of flat the salesman has
export type RowInfo = {
	Tier: number,
	Text: string,
}
export type ActionInfo =
	{
		Type: "Purchase", -- a flat is asked for
		Tier: number,
	}
	| {
		Type: "Exit", -- the panel slid back out
	}
export type Properties = RobloxComponents.FrameProperties & {
	Title: string,
	-- what the salesman says until there's an answer to read
	Text: string,
	-- in the order they're listed, at most as many as the panel has room for
	Rows: { RowInfo },
	-- the answer to the last ask, read in place of what he says for as long as it's handed in
	Message: string?,
	-- an ask is on its way: a press on a row is one too many
	IsBusy: boolean?,
	OnAction: (ActionInfo) -> (),
}
-- Constants
-- the picture of the panel is a square of this much of the width of the screen, larger than the panel that's seen
local PANEL_SIZE = UDim2.fromScale(0.35, 0.35)
local OPEN_POSITION = UDim2.fromScale(0.5, 0.5)
-- where it's kept, off the right edge of the screen
local AWAY_POSITION = UDim2.fromScale(1.5, 0.5)
-- everything below is laid out in scale of that square, where the dialog of the look has its own
local TITLE_POSITION = UDim2.fromScale(0.5, 0.26)
local TITLE_SIZE = UDim2.fromScale(0.5, 0.08)
local BODY: Area = table.freeze({
	Position = UDim2.fromScale(0.0759, 0.3675),
	Size = UDim2.fromScale(0.8498, 0.09),
})
-- each is the one wide button of the dialog, by its middle
local ROW_SIZE = UDim2.fromScale(0.45, 0.08)
local ROW_HEIGHTS = table.freeze({ 0.495, 0.58, 0.665, 0.75 })
-- the corner of the panel that's seen
local EXIT_POSITION = UDim2.fromScale(0.9, 0.24)
-- a look without a picture has its box behind all of the above
local FRAME_AREA: Area = table.freeze({
	Position = UDim2.fromScale(0.05, 0.19),
	Size = UDim2.fromScale(0.9, 0.61),
})
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- what the salesman of the apartment tower has to sell. the old place had the engine's own dialog bubble for it, which
-- said yes to whoever picked a line, paid for or not. this is the panel of the look with a row per kind of flat: it
-- comes in from the right, reads the answer of the server + leaves by its exit
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local palette = style.Palette
	local panel = style.Panel
	local border = style.Border
	local buttonImage = style.Widgets.Dialog.ButtonImage
	assert(#props.Rows <= #ROW_HEIGHTS, `the panel has room for {#ROW_HEIGHTS} flats, not {#props.Rows}`)
	local panelRef, initialPosition, close = useSlide(OPEN_POSITION, AWAY_POSITION, style.Motion.Slide, function()
		props.OnAction({
			Type = "Exit",
		})
	end)
	-- a press on a panel that's on its way out is one too many
	local isLeavingRef = React.useRef(false)

	local rows: { [string]: React.ReactNode } = {}
	for index, rowInfo in props.Rows do
		rows[`Row-{rowInfo.Tier}`] = e(
			"ImageButton",
			{
				AnchorPoint = Vector2.new(0.5, 0.5),
				-- the button itself isn't seen, it's the bar behind what it says
				BackgroundTransparency = 1,
				Position = UDim2.fromScale(0.5, ROW_HEIGHTS[index]),
				Size = ROW_SIZE,
				ZIndex = 2,
				[React.Event.Activated] = function()
					if isLeavingRef.current or props.IsBusy then
						return
					end
					props.OnAction({
						Type = "Purchase",
						Tier = rowInfo.Tier,
					})
				end,
			} :: RobloxComponents.ImageButtonProperties,
			{
				-- the bar is in the middle band of a square picture, so that's as tall as the button is wide
				Bar = if buttonImage
					then e("ImageLabel", {
						AnchorPoint = Vector2.new(0.5, 0.5),
						BackgroundTransparency = 1,
						ImageContent = Content.fromUri(buttonImage),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(1, 1),
						SizeConstraint = Enum.SizeConstraint.RelativeXX,
					})
					else e("Frame", {
						BackgroundColor3 = palette.FieldAlt,
						BorderColor3 = border.Color3,
						BorderSizePixel = border.SizePixel,
						Size = UDim2.fromScale(1, 1),
					}),
				Label = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = style.Fonts.Body,
					Size = UDim2.fromScale(1, 1),
					Text = rowInfo.Text,
					TextColor3 = palette.Text,
					TextSize = style.TextSizes.Button,
					TextWrapped = true,
					ZIndex = 2,
				}),
			}
		)
	end

	return e(RobloxComponents.Frame(
		{
			Active = false,
			BackgroundTransparency = 1,
		},
		props,
		{
			Panel = e("Frame", {
				ref = panelRef,
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundTransparency = 1,
				Position = initialPosition,
				Size = PANEL_SIZE,
				SizeConstraint = Enum.SizeConstraint.RelativeXX,
			}, {
				Art = if panel.Type == "Image"
					then e("ImageLabel", {
						BackgroundTransparency = 1,
						ImageColor3 = panel.ImageColor3,
						ImageContent = Content.fromUri(panel.Image),
						ScaleType = panel.ScaleType,
						SliceCenter = panel.SliceCenter,
						Size = UDim2.fromScale(1, 1),
					})
					elseif panel.Type == "Engine" then e("Frame", {
						Position = FRAME_AREA.Position,
						Size = FRAME_AREA.Size,
						Style = panel.Style,
					})
					else e("Frame", {
						BackgroundColor3 = panel.BackgroundColor3,
						BackgroundTransparency = panel.BackgroundTransparency,
						BorderColor3 = panel.BorderColor3,
						BorderSizePixel = panel.BorderSizePixel,
						Position = FRAME_AREA.Position,
						Size = FRAME_AREA.Size,
					}),
				-- a picture has its own heading drawn where this is, the tag covers it with whose flats these are
				Title = e("TextLabel", {
					AnchorPoint = Vector2.new(0.5, 0.5),
					BackgroundColor3 = palette.Accent,
					BorderSizePixel = 0,
					FontFace = style.Fonts.Heading,
					Position = TITLE_POSITION,
					Size = TITLE_SIZE,
					Text = props.Title,
					TextColor3 = palette.TextOnAccent,
					TextScaled = true,
					TextWrapped = true,
					ZIndex = 2,
				}),
				-- two lines over the rows: written as large as the look writes, smaller where that doesn't fit
				Body = e("TextLabel", {
					BackgroundTransparency = 1,
					FontFace = style.Fonts.Body,
					Position = BODY.Position,
					Size = BODY.Size,
					Text = props.Message or props.Text,
					TextColor3 = palette.Text,
					TextScaled = true,
					TextWrapped = true,
					ZIndex = 2,
				}, {
					UITextSizeConstraint = e("UITextSizeConstraint", {
						MaxTextSize = style.TextSizes.Body,
					}),
				}),
				Rows = e(React.Fragment, {}, rows),
				Exit = e(
					ExitButton,
					{
						Position = EXIT_POSITION,
						ZIndex = 3,
						[React.Event.Activated] = function()
							isLeavingRef.current = true
							close()
						end,
					} :: ExitButton.Properties
				),
			}),
		}
	))
end
