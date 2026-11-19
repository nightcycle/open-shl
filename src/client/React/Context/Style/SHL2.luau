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
local BLACK = Color3.new()
-- the edge the engine gives a box, spelt out by every panel
local BORDER_COLOR = Color3.fromRGB(27, 42, 53)
local HEADING_FONT =
	Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local BODY_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local NOTE_FONT = Font.new("rbxasset://fonts/families/ComicNeueAngular.json")
local SLIDE_TWEEN_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
-- the look the widgets were written in: dark see-through boxes with white text on them
local STYLE: Style = {
	Palette = {
		Accent = Color3.fromRGB(255, 175, 0),
		AccentLight = Color3.fromRGB(26, 167, 255),
		Field = BLACK,
		FieldAlt = Color3.fromRGB(35, 35, 35),
		Text = WHITE,
		TextStrong = WHITE,
		TextOnAccent = BORDER_COLOR,
		Positive = Color3.fromRGB(0, 170, 0),
		Negative = Color3.fromRGB(255, 0, 0),
		Warning = Color3.fromRGB(255, 204, 0),
	},
	Fonts = {
		Heading = HEADING_FONT,
		Body = BODY_FONT,
		Note = NOTE_FONT,
	},
	TextSizes = {
		Body = 20,
		Button = 18,
		Note = 14,
	},
	Border = {
		Color3 = BORDER_COLOR,
		SizePixel = 1,
	},
	Panel = {
		Type = "Frame",
		BackgroundColor3 = BLACK,
		BackgroundTransparency = 0.5,
		BorderColor3 = BORDER_COLOR,
		BorderSizePixel = 1,
	},
	Motion = {
		Slide = SLIDE_TWEEN_INFO,
		-- its panels only ever slide
		Open = SLIDE_TWEEN_INFO,
		Close = SLIDE_TWEEN_INFO,
	},
	Widgets = {
		BalanceCounter = {
			BackgroundColor3 = WHITE,
			BorderColor3 = WHITE,
			BorderSizePixel = 2,
			TextColors = {
				Credits = Color3.fromRGB(0, 170, 0),
				Gems = Color3.fromRGB(255, 0, 0),
			},
			TextStrokeTransparency = 0,
			TextXAlignment = Enum.TextXAlignment.Right,
		},
		-- it never had one, what's asked in it stands in a box like any of its panels
		Dialog = {},
		ExitButton = {
			Image = Image.core.ui["exit.png"],
			Size = UDim2.fromOffset(40, 40),
		},
		NameTag = {
			FontFace = BODY_FONT,
			TextColor3 = WHITE,
			TextStrokeTransparency = 0,
			Name = {
				Position = UDim2.fromScale(0, 0.135),
				Size = UDim2.fromScale(1, 0.15),
			},
			Away = {
				Text = "AFK",
				FontFace = Font.new(
					"rbxasset://fonts/families/Arial.json",
					Enum.FontWeight.Bold,
					Enum.FontStyle.Normal
				),
				TextColor3 = Color3.fromRGB(223, 60, 60),
			},
		},
		ServerId = {
			Backing = {
				BackgroundColor3 = BLACK,
				BorderColor3 = BORDER_COLOR,
			},
			FontFace = NOTE_FONT,
			TextColor3 = WHITE,
		},
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return STYLE
