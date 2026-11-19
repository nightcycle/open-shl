--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
local StyleTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Types")
type Style = StyleTypes.Style
-- Constants
local WHITE = Color3.new(1, 1, 1)
local ACCENT_COLOR = Color3.fromRGB(20, 166, 230)
local FIELD_ALT_COLOR = Color3.fromRGB(232, 232, 232)
local HEADING_FONT =
	Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local BODY_FONT = Font.new("rbxasset://fonts/families/ComicNeueAngular.json")
local NOTE_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
-- the look of the legacy place: white + light grey fields in blue frames, all of it drawn into the art. nothing has a
-- corner, a stroke or a border of its own
local STYLE: Style = {
	Palette = {
		Accent = ACCENT_COLOR,
		AccentLight = Color3.fromRGB(57, 187, 234),
		Field = WHITE,
		FieldAlt = FIELD_ALT_COLOR,
		Text = Color3.fromRGB(126, 126, 126),
		TextStrong = Color3.fromRGB(57, 57, 57),
		TextOnAccent = WHITE,
		Positive = Color3.fromRGB(43, 178, 56),
		Negative = Color3.fromRGB(183, 53, 53),
		Warning = Color3.fromRGB(255, 213, 0),
	},
	Fonts = {
		Heading = HEADING_FONT,
		Body = BODY_FONT,
		Note = NOTE_FONT,
	},
	TextSizes = {
		Body = 30,
		Button = 20,
		Note = 14,
	},
	Border = {
		Color3 = ACCENT_COLOR,
		SizePixel = 0,
	},
	-- the art of its yes / no dialog, which is what any panel without a picture of its own was drawn on
	Panel = {
		Type = "Image",
		Image = Image["shl-3"].ui["team-change"]["panel.png"],
		ImageColor3 = WHITE,
		ScaleType = Enum.ScaleType.Stretch,
		Body = {
			Position = UDim2.fromScale(0.0759, 0.3675),
			Size = UDim2.fromScale(0.8498, 0.2838),
		},
	},
	Motion = {
		Slide = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Open = TweenInfo.new(0.35, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
		Close = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
	},
	Widgets = {
		-- it never drew a balance, the credits were a column of the player list. this one is a cell of its fields with
		-- the blue its headings are written in
		BalanceCounter = {
			BackgroundColor3 = FIELD_ALT_COLOR,
			BorderColor3 = ACCENT_COLOR,
			BorderSizePixel = 0,
			TextColors = {
				Credits = ACCENT_COLOR,
				Gems = ACCENT_COLOR,
			},
		},
		-- the grey bar its yes, no + okay were written on
		Dialog = {
			ButtonImage = Image["shl-3"].ui.common["button-template-3.png"],
		},
		ExitButton = {
			Image = Image["shl-3"].ui.common["exit.png"],
			Size = UDim2.fromOffset(40, 40),
		},
		-- the label every character had over its head: read from up close only, the name gives way to the backstory
		-- for a while + nobody is marked as away
		NameTag = {
			FontFace = NOTE_FONT,
			TextColor3 = WHITE,
			TextSize = 22,
			TextStrokeColor3 = WHITE,
			TextStrokeTransparency = 0.6,
			MaxDistance = 42,
			Name = {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.13),
				Size = UDim2.fromScale(2, 0.2),
			},
			Bio = {
				AnchorPoint = Vector2.new(0.5, 0.55),
				Position = UDim2.fromScale(0.5, 0.11),
				Size = UDim2.fromScale(2.5, 0.4),
			},
			Placeholder = "Choosing Suit",
		},
		-- the version label it had in the corner
		ServerId = {
			FontFace = HEADING_FONT,
			TextColor3 = WHITE,
			TextSize = 14,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextYAlignment = Enum.TextYAlignment.Bottom,
		},
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return STYLE
