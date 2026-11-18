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
		FieldAlt = Color3.fromRGB(232, 232, 232),
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
		Image = Image.shl3.ui["team-change"]["panel.png"],
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
		ExitButton = {
			Image = Image.shl3.ui.common["exit.png"],
			Size = UDim2.fromOffset(40, 40),
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
