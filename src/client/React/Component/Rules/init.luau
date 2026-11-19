--!strict
--!native
-- Services
-- Packages
local React = require("@game/ReplicatedStorage/Packages/React")
local RobloxComponents = require("@game/ReplicatedStorage/Packages/RobloxComponents")
-- Modules
-- Components
-- Hooks
-- Contexts
local StyleContext = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style")
-- Types
export type ActionInfo = {
	Type: "Agree",
}
export type Properties = RobloxComponents.FrameProperties & {
	OnAction: (ActionInfo) -> (),
}
-- Constants
-- every number in here is the old page's, in scale of the screen or of the box that holds it
-- the teal of every page that fills the screen
local PAGE_COLOR = Color3.fromRGB(0, 143, 156)
local CARD_COLOR = Color3.new(1, 1, 1)
local TITLE_SIZE = UDim2.fromScale(1, 0.2)
local TITLE_TEXT = "WELCOME"
local BOX_POSITION = UDim2.fromScale(0.3, 0.2)
local BOX_SIZE = UDim2.fromScale(0.4, 0.5)
-- what's read is twice as tall as the box it's read in
local CANVAS_SIZE = UDim2.fromScale(0, 2)
local SCROLL_BAR_THICKNESS = 12
-- the plain black square the engine ships, for all three parts of the bar
local SCROLL_BAR_IMAGE = "rbxasset://textures/blackBkg_square.png"
-- the paragraphs were never given a font: they're in the one a label starts out with
local PARAGRAPH_FONT = Font.new("rbxasset://fonts/families/LegacyArial.json")
local PARAGRAPH_COLOR = Color3.new()
-- each takes a third of what's read + stands in from its sides
local PARAGRAPH_SIZE = UDim2.fromScale(0.8, 0.33)
local PARAGRAPH_X = 0.1
local PARAGRAPHS: { string } = table.freeze({
	"Welcome to Super Hero Life! Here's some information that I consider necessary to enjoy and understand the game! For starters you are allowed to be a villain if you want to - the current costumes are mostly tailored to heroes, but I assure you once I find a nice generic design I like, I will release some for villains.",
	"Secondly I want you to have fun! Just make sure that while having fun you don't ruin anyone else's experience - by this I mean don't harass people or be overly rude to others. Lastly I want you to know that I want you to message me! Feel free to send me a personal message if you have an idea, see a bug, etc.",
	'I only ask that you refrain from asking for donations, free VIP, and also please spell "please" correctly (sorry... but it\'s a pet peeve of mine.) Follow me on twitter @BroRubiks if you want to receive codes for this game or want to learn about future updates. Also after you leave please remember to rate my game!',
})
local AGREE_POSITION = UDim2.fromScale(0.35, 0.75)
local AGREE_SIZE = UDim2.fromScale(0.3, 0.1)
local AGREE_TEXT = "I Agree"
-- Variables
-- References
-- Private Functions
local e = React.createElement
-- Class
-- the rules of the game on a page that fills the screen: a title, three paragraphs to scroll through on a white box +
-- the one button that leads on. nothing else is reached before it's pressed
return function(props: Properties): React.ReactNode
	local style = React.useContext(StyleContext)
	local border = style.Border

	local paragraphs: { [string]: React.ReactNode } = {}
	for index, text in PARAGRAPHS do
		paragraphs[`Paragraph-{index}`] = e("TextLabel", {
			BackgroundTransparency = 1,
			FontFace = PARAGRAPH_FONT,
			Position = UDim2.fromScale(PARAGRAPH_X, (index - 1) * PARAGRAPH_SIZE.Y.Scale),
			Size = PARAGRAPH_SIZE,
			Text = text,
			TextColor3 = PARAGRAPH_COLOR,
			TextScaled = true,
			TextWrapped = true,
		})
	end

	return e(RobloxComponents.Frame(
		{
			BackgroundTransparency = 1,
		},
		props,
		{
			-- the page, behind the top bar as well
			Backdrop = e("Frame", {
				Active = true,
				BackgroundColor3 = PAGE_COLOR,
				BorderSizePixel = 0,
				Position = UDim2.fromScale(0, -1),
				Size = UDim2.fromScale(1, 2),
				ZIndex = -1,
			}),

			Title = e("TextLabel", {
				BackgroundTransparency = 1,
				FontFace = style.Fonts.Heading,
				Size = TITLE_SIZE,
				Text = TITLE_TEXT,
				TextColor3 = style.Palette.Text,
				TextScaled = true,
				TextWrapped = true,
			}),

			Box = e(
				"ScrollingFrame",
				{
					BackgroundColor3 = CARD_COLOR,
					BorderColor3 = border.Color3,
					BorderSizePixel = border.SizePixel,
					BottomImage = SCROLL_BAR_IMAGE,
					CanvasSize = CANVAS_SIZE,
					MidImage = SCROLL_BAR_IMAGE,
					Position = BOX_POSITION,
					ScrollBarThickness = SCROLL_BAR_THICKNESS,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					Size = BOX_SIZE,
					TopImage = SCROLL_BAR_IMAGE,
				} :: RobloxComponents.ScrollingFrameProperties,
				paragraphs
			),

			Agree = e("TextButton", {
				BackgroundColor3 = CARD_COLOR,
				BorderColor3 = border.Color3,
				BorderSizePixel = border.SizePixel,
				FontFace = style.Fonts.Body,
				Position = AGREE_POSITION,
				Size = AGREE_SIZE,
				Text = AGREE_TEXT,
				-- a card is written on in the dark of its edge
				TextColor3 = border.Color3,
				TextScaled = true,
				TextWrapped = true,
				[React.Event.Activated] = function()
					props.OnAction({
						Type = "Agree",
					})
				end,
			}),
		}
	))
end
