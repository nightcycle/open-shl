--!strict
-- Services
-- Packages
-- Modules
-- Types
local StyleTypes = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Context/Style/Types")
type Style = StyleTypes.Style
-- Constants
local WHITE = Color3.new(1, 1, 1)
local PANEL_COLOR = Color3.new(0, 0, 1)
local ACCENT_COLOR = Color3.fromRGB(255, 170, 0)
local BALANCE_COLOR = Color3.fromRGB(0, 85, 255)
local NEGATIVE_COLOR = Color3.fromRGB(255, 0, 0)
-- the edge + the text the engine gives a box: what every white button + row of it was left with
local DEFAULT_COLOR = Color3.fromRGB(27, 42, 53)
local HEADING_FONT = Font.new("rbxasset://fonts/families/Arial.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
local BODY_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json")
local NOTE_FONT = Font.new("rbxasset://fonts/families/SourceSansPro.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
-- a panel of it is put where it's shown, it doesn't travel
local CUT_TWEEN_INFO = TweenInfo.new(0, Enum.EasingStyle.Linear, Enum.EasingDirection.Out)
-- the look of the legacy place: see-through pure blue boxes with white text scaled into them, orange for what's pressed
-- to get somewhere. there's no art, no corner + no stroke in it, the one picture it has is the logo it loads under
local STYLE: Style = {
	Palette = {
		Accent = ACCENT_COLOR,
		AccentLight = BALANCE_COLOR, -- the box the balance stands on
		Field = PANEL_COLOR,
		FieldAlt = Color3.fromRGB(85, 85, 255), -- a row under a row
		Text = WHITE,
		TextStrong = ACCENT_COLOR, -- the balance + what was picked
		TextOnAccent = WHITE,
		Positive = Color3.fromRGB(0, 170, 0),
		Negative = NEGATIVE_COLOR,
		Warning = Color3.fromRGB(255, 209, 42),
	},
	Fonts = {
		Heading = HEADING_FONT,
		Body = BODY_FONT,
		Note = NOTE_FONT,
	},
	-- nearly all of it is scaled, the little that isn't is 14
	TextSizes = {
		Body = 14,
		Button = 14,
		Note = 14,
	},
	Border = {
		Color3 = DEFAULT_COLOR,
		SizePixel = 1,
	},
	-- what it opened over the game was left to the engine to draw: its shop, its saves + the list it loaded one from.
	-- the blue of its creator is a field at the see-through of whichever screen draws it
	Panel = {
		Type = "Engine",
		Style = Enum.FrameStyle.RobloxRound,
	},
	Motion = {
		-- the four things of it that ever traveled all did it this way
		Slide = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		Open = CUT_TWEEN_INFO,
		Close = CUT_TWEEN_INFO,
	},
	Widgets = {
		-- "Currency: 123" in bold orange on a blue box under the ticker, the game behind it shows through
		BalanceCounter = {
			BackgroundColor3 = BALANCE_COLOR,
			BackgroundTransparency = 0.4,
			BorderColor3 = DEFAULT_COLOR,
			BorderSizePixel = 0,
			TextColors = {
				Credits = ACCENT_COLOR,
				Gems = ACCENT_COLOR,
			},
			FontFace = NOTE_FONT,
			Prefix = "Currency: ",
		},
		-- the one box it ever had something to say in: white with a thick edge, a red word over what went wrong in
		-- black. that took the upper half of it. it had no button, one stands in the lower half where its pun was
		Dialog = {
			Card = {
				BackgroundColor3 = WHITE,
				BorderColor3 = DEFAULT_COLOR,
				BorderSizePixel = 3,
				FontFace = HEADING_FONT,
				TitleColor3 = NEGATIVE_COLOR,
				TextColor3 = Color3.new(),
				Title = {
					Position = UDim2.fromScale(0, 0),
					Size = UDim2.fromScale(1, 0.2),
				},
				Body = {
					Position = UDim2.fromScale(0, 0.2),
					Size = UDim2.fromScale(1, 0.3),
				},
				Buttons = {
					Position = UDim2.fromScale(0, 0.675),
					Size = UDim2.fromScale(1, 0.15),
				},
			},
		},
		-- it never drew one: what shut its saves was this word on an orange box, three times as wide as it's tall
		ExitButton = {
			Type = "Text",
			Text = "EXIT",
			Size = UDim2.fromOffset(126, 40),
			FontFace = HEADING_FONT,
			TextColor3 = DEFAULT_COLOR,
			BackgroundColor3 = ACCENT_COLOR,
			BorderColor3 = DEFAULT_COLOR,
			BorderSizePixel = 0,
		},
		-- the name the engine wrote over a body, read from 100 studs off. where it stands is the kit's, the engine
		-- left no number for it
		NameTag = {
			FontFace = BODY_FONT,
			TextColor3 = WHITE,
			TextStrokeTransparency = 0,
			MaxDistance = 100,
			Name = {
				Position = UDim2.fromScale(0, 0.135),
				Size = UDim2.fromScale(1, 0.15),
			},
			-- who fights + who doesn't was a column of the player list, here it's a smaller line between the name +
			-- the head
			Mode = {
				Position = UDim2.fromScale(0, 0.285),
				Size = UDim2.fromScale(1, 0.09),
			},
		},
		-- it showed no version anywhere: the id stands the way the one line of its ticker did, white on a black bar
		ServerId = {
			Backing = {
				BackgroundColor3 = Color3.new(),
				BorderColor3 = DEFAULT_COLOR,
			},
			FontFace = BODY_FONT,
			TextColor3 = WHITE,
		},
	},
}
-- Variables
-- References
-- Private Functions
-- Class
return STYLE
