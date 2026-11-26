--!strict
-- Services
-- Packages
-- Modules
-- Types
local Types = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/Wizard/Types")
type Box = Types.Box
type NameInfo = Types.NameInfo
type PageInfo = Types.PageInfo
type RowInfo = Types.RowInfo
-- Constants
-- every number in here is the old creator's, in scale of the screen or of the box that holds it: it had no anchor, no
-- layout + nothing sized in pixels
-- what a swatch of the grid is drawn in, row by row. it's not the color a pick paints: that one is the color of the
-- game's palette at the same place, which the old buttons only came close to
local SWATCH_COLORS: { Color3 } = table.freeze({
	Color3.fromRGB(165, 207, 13), -- Br. yellowish green
	Color3.fromRGB(255, 234, 3), -- Bright yellow
	Color3.fromRGB(234, 156, 0), -- Bright orange
	Color3.fromRGB(214, 0, 0), -- Bright red
	Color3.fromRGB(132, 11, 141), -- Bright violet
	Color3.fromRGB(0, 98, 255), -- Bright blue
	Color3.fromRGB(26, 147, 198), -- Bright bluish green
	Color3.fromRGB(55, 159, 7), -- Bright green
	Color3.fromRGB(255, 255, 255), -- Institutional white
	Color3.fromRGB(241, 241, 241), -- White
	Color3.fromRGB(231, 231, 231), -- Light stone grey
	Color3.fromRGB(204, 204, 204), -- Mid gray
	Color3.fromRGB(188, 188, 188), -- Medium stone grey
	Color3.fromRGB(108, 108, 108), -- Dark stone grey
	Color3.fromRGB(44, 44, 44), -- Black
	Color3.fromRGB(0, 0, 0), -- Really black
	Color3.fromRGB(111, 141, 79), -- Grime
	Color3.fromRGB(255, 170, 0), -- Br. yellowish orange
	Color3.fromRGB(255, 210, 137), -- Light orange
	Color3.fromRGB(166, 132, 132), -- Sand red
	Color3.fromRGB(146, 108, 156), -- Lavender
	Color3.fromRGB(120, 142, 152), -- Sand blue
	Color3.fromRGB(139, 201, 255), -- Medium blue
	Color3.fromRGB(145, 167, 130), -- Sand green
	Color3.fromRGB(212, 199, 158), -- Brick yellow
	Color3.fromRGB(255, 248, 148), -- Cool yellow
	Color3.fromRGB(255, 150, 75), -- Neon orange
	Color3.fromRGB(255, 176, 156), -- Medium red
	Color3.fromRGB(255, 211, 252), -- Light reddish violet
	Color3.fromRGB(173, 221, 230), -- Pastel Blue
	Color3.fromRGB(0, 255, 255), -- Teal
	Color3.fromRGB(158, 197, 127), -- Medium green
	Color3.fromRGB(255, 227, 171), -- Pastel brown
	Color3.fromRGB(252, 255, 215), -- Pastel yellow
	Color3.fromRGB(255, 217, 210), -- Pastel orange
	Color3.fromRGB(255, 135, 245), -- Pink
	Color3.fromRGB(170, 170, 255), -- Pastel violet
	Color3.fromRGB(196, 251, 255), -- Pastel light blue
	Color3.fromRGB(203, 250, 255), -- Pastel blue-green
	Color3.fromRGB(221, 255, 220), -- Pastel green
	Color3.fromRGB(170, 170, 0), -- Olive
	Color3.fromRGB(255, 255, 0), -- New Yeller
	Color3.fromRGB(255, 170, 0), -- Deep orange
	Color3.fromRGB(255, 0, 0), -- Really red
	Color3.fromRGB(255, 0, 255), -- Hot pink
	Color3.fromRGB(0, 0, 255), -- Really blue
	Color3.fromRGB(0, 255, 255), -- Toothpaste
	Color3.fromRGB(85, 255, 0), -- Lime green
	Color3.fromRGB(134, 101, 61), -- Brown
	Color3.fromRGB(216, 161, 113), -- Nougat
	Color3.fromRGB(153, 96, 63), -- Dark orange
	Color3.fromRGB(137, 2, 255), -- Royal purple
	Color3.fromRGB(197, 170, 255), -- Alder
	Color3.fromRGB(0, 170, 255), -- Cyan
	Color3.fromRGB(193, 217, 255), -- Light blue
	Color3.fromRGB(63, 127, 0), -- Camo
	Color3.fromRGB(85, 55, 55), -- Reddish brown
	Color3.fromRGB(159, 99, 30), -- CGA brown
	Color3.fromRGB(130, 81, 71), -- Dusty Rose
	Color3.fromRGB(170, 0, 127), -- Magenta
	Color3.fromRGB(35, 108, 172), -- Deep blue
	Color3.fromRGB(0, 0, 127), -- Navy blue
	Color3.fromRGB(0, 127, 74), -- Dark green
	Color3.fromRGB(0, 75, 37), -- Earth green
})
local PANEL_SIZE = UDim2.fromScale(0.3, 0.75)
-- the panel of a grid ends under it
local PALETTE_PANEL_SIZE = UDim2.fromScale(0.3, 0.6)
-- a title over rows stands a little way down its panel, one over anything else at its top
local ROWS_TITLE_BOX: Box = table.freeze({
	Position = UDim2.fromScale(0.1, 0.05),
	Size = UDim2.fromScale(0.8, 0.2),
})
local TITLE_BOX: Box = table.freeze({
	Position = UDim2.fromScale(0.1, 0),
	Size = UDim2.fromScale(0.8, 0.15),
})
-- alone at the foot of its panel a button is in the middle, with the one to rent beside it it's at the left
local MIDDLE_FORWARD_BOX: Box = table.freeze({
	Position = UDim2.fromScale(0.3, 0.875),
	Size = UDim2.fromScale(0.4, 0.1),
})
local ROW_SIZE = UDim2.fromScale(0.95, 0.1)
-- the page of the costume has more rows than a panel holds of the usual ones
local SLIM_ROW_SIZE = UDim2.fromScale(0.95, 0.065)
-- a row under a row, in scale of the one it hangs on: a little narrower + lower, the first a fifth of a row below it
local NESTED_ROW_SIZE = UDim2.fromScale(0.95, 0.75)
local NESTED_ROW_X = 0.025
local NESTED_ROW_Y = 1.2
-- the pieces a suit is worn in, top to bottom: each steps through the same suits as the row they hang on
local SUIT_PIECES: { string } = table.freeze({ "LEFT ARM", "RIGHT ARM", "TORSO", "LEFT LEG", "RIGHT LEG" })
local SUIT_PIECE_ROWS: { RowInfo } = {}
for index, piece in SUIT_PIECES do
	local row: RowInfo = {
		Text = piece,
		Source = {
			Type = "Items",
			Folder = `Costume/{piece}`,
			IsPassingLocked = true,
		},
		Position = UDim2.fromScale(NESTED_ROW_X, NESTED_ROW_Y + index - 1),
		Size = NESTED_ROW_SIZE,
		IsNested = true,
	}
	table.insert(SUIT_PIECE_ROWS, row)
end
-- what the secret identity is told apart by
local SECRET_IDENTITY_ROWS: { RowInfo } = {
	{
		Text = "FACES",
		Source = {
			Type = "Items",
			Folder = "Secret Identity/FACES",
		},
		Position = UDim2.fromScale(0.025, 0.375),
		Size = ROW_SIZE,
	},
	{
		Text = "HAIR",
		Source = {
			Type = "Items",
			Folder = "Secret Identity/HAIR",
			HasNone = true,
		},
		Position = UDim2.fromScale(0.025, 0.5),
		Size = ROW_SIZE,
	},
}
-- a suit whole or piece by piece, then what's worn over it. the last row is the only one more than one is kept of
local COSTUME_ROWS: { RowInfo } = {
	{
		Text = "SUITS",
		Source = {
			Type = "Sets",
			Folder = "Costume/SUITS",
		},
		Position = UDim2.fromScale(0.025, 0.125),
		Size = SLIM_ROW_SIZE,
		Rows = SUIT_PIECE_ROWS,
	},
	{
		Text = "CAPES",
		Source = {
			Type = "Items",
			Folder = "Costume/CAPES",
			HasNone = true,
		},
		Position = UDim2.fromScale(0.025, 0.525),
		Size = SLIM_ROW_SIZE,
	},
	{
		Text = "MASKS",
		Source = {
			Type = "Items",
			Folder = "Costume/MASKS",
			HasNone = true,
		},
		Position = UDim2.fromScale(0.025, 0.6),
		Size = SLIM_ROW_SIZE,
	},
	{
		Text = "EMBLEMS",
		Source = {
			Type = "Items",
			Folder = "Costume/EMBLEMS",
		},
		Position = UDim2.fromScale(0.025, 0.675),
		Size = SLIM_ROW_SIZE,
	},
	{
		Text = "OTHER",
		Source = {
			Type = "Extras",
			Folder = "Costume/OTHER",
		},
		Position = UDim2.fromScale(0.025, 0.75),
		Size = SLIM_ROW_SIZE,
	},
}
-- a switch for each of the three colors of the costume
local NEON_ROWS: { RowInfo } = {
	{
		Text = "Primary",
		Source = {
			Type = "Glow",
			Field = 1,
		},
		Position = UDim2.fromScale(0.025, 0.25),
		Size = ROW_SIZE,
	},
	{
		Text = "Secondary",
		Source = {
			Type = "Glow",
			Field = 2,
		},
		Position = UDim2.fromScale(0.025, 0.4),
		Size = ROW_SIZE,
	},
	{
		Text = "Tertiary",
		Source = {
			Type = "Glow",
			Field = 3,
		},
		Position = UDim2.fromScale(0.025, 0.55),
		Size = ROW_SIZE,
	},
}
-- one power of each slot of the game, spaced apart for the name of the pick under each
local ABILITY_ROWS: { RowInfo } = {
	{
		Text = "MELEE",
		Source = {
			Type = "Power",
			Field = 1,
		},
		Position = UDim2.fromScale(0.025, 0.15),
		Size = ROW_SIZE,
	},
	{
		Text = "RANGED",
		Source = {
			Type = "Power",
			Field = 2,
		},
		Position = UDim2.fromScale(0.025, 0.4),
		Size = ROW_SIZE,
	},
	{
		Text = "SPECIAL",
		Source = {
			Type = "Power",
			Field = 3,
		},
		Position = UDim2.fromScale(0.025, 0.65),
		Size = ROW_SIZE,
	},
}
-- the one row reads the side that's picked
local ALIGNMENT_ROWS: { RowInfo } = {
	{
		Text = "HERO",
		Source = {
			Type = "Choice",
			Field = 1,
		},
		Position = UDim2.fromScale(0.025, 0.4),
		Size = ROW_SIZE,
	},
}
-- the name of the secret identity is asked for first
local NAME_BARS: { NameInfo } = {
	{
		Field = 1,
		Position = UDim2.fromScale(0.025, 0.35),
	},
	{
		Field = 2,
		Position = UDim2.fromScale(0.025, 0.55),
	},
}
-- the one row reads whether the player fights
local MODE_ROWS: { RowInfo } = {
	{
		Text = "PVP",
		Source = {
			Type = "Mode",
		},
		Position = UDim2.fromScale(0.025, 0.4),
		Size = ROW_SIZE,
	},
}
-- the pages in the order they're walked, each under the key of the page of the game's editor it edits. the secret
-- identity is made first + stands in the booth until its colors are picked, the hero for the rest of the way
local PAGES: { PageInfo } = {
	{
		Key = "Promo",
		Kind = "Cover",
		IdentityKey = "Secret",
		Titles = { "GET FREE STUFF!" },
		TitleBox = {
			Position = UDim2.fromScale(0, 0),
			Size = UDim2.fromScale(1, 0.2),
		},
		Lines = {
			{
				Text = "Want extra emblems for your hero?",
				Box = {
					Position = UDim2.fromScale(0, 0.2),
					Size = UDim2.fromScale(1, 0.08),
				},
			},
			{
				Text = "Join Deadly Pineapple Games!",
				Box = {
					Position = UDim2.fromScale(0, 0.3),
					Size = UDim2.fromScale(1, 0.16),
				},
				IsBold = true,
				IsWarning = true,
			},
			{
				Text = "Being a member of this group unlocks multiple exclusive emblems!",
				Box = {
					Position = UDim2.fromScale(0, 0.5),
					Size = UDim2.fromScale(1, 0.16),
				},
			},
		},
		Forward = {
			Text = "CONTINUE",
			Box = {
				Position = UDim2.fromScale(0.35, 0.75),
				Size = UDim2.fromScale(0.3, 0.1),
			},
			IsCard = true,
		},
		IsGroupAsked = true,
	},
	{
		Key = "Secret Identity",
		Kind = "Rows",
		IdentityKey = "Secret",
		Titles = { "Secret Identity" },
		TitleBox = ROWS_TITLE_BOX,
		PanelSize = PANEL_SIZE,
		Help = "Now you can decide what your character's secret identity will look like! You can purchase some articles with cash while some are unlocked with gamepasses.",
		Rows = SECRET_IDENTITY_ROWS,
		Forward = {
			Text = "Continue",
			Box = {
				Position = UDim2.fromScale(0.05, 0.75),
				Size = UDim2.fromScale(0.4, 0.1),
			},
		},
		Rent = {
			Position = UDim2.fromScale(0.55, 0.75),
			Size = UDim2.fromScale(0.4, 0.1),
		},
	},
	{
		Key = "Colors",
		Kind = "Palette",
		IdentityKey = "Secret",
		Titles = { "SKIN COLOR", "HAIR COLOR" },
		TitleBox = TITLE_BOX,
		PanelSize = PALETTE_PANEL_SIZE,
		Help = "Now time to decide your hair color and skin color! There are currently only 64 options!",
		IsSlidingOut = true,
	},
	{
		Key = "Costume",
		Kind = "Rows",
		IdentityKey = "Main",
		Titles = { "Costume" },
		TitleBox = {
			Position = UDim2.fromScale(0.1, 0),
			Size = UDim2.fromScale(0.8, 0.125),
		},
		PanelSize = UDim2.fromScale(0.3, 0.85),
		Help = "Now let's build the actual costume of your character! Keep in mind not all suits are free to wear, some require a gamepass!",
		Rows = COSTUME_ROWS,
		Forward = {
			Text = "Continue",
			Box = {
				Position = UDim2.fromScale(0.05, 0.913),
				Size = UDim2.fromScale(0.4, 0.075),
			},
		},
		Rent = {
			Position = UDim2.fromScale(0.55, 0.913),
			Size = UDim2.fromScale(0.4, 0.075),
		},
	},
	{
		Key = "Costume Colors",
		Kind = "Palette",
		IdentityKey = "Main",
		Titles = { "PRIMARY", "SECONDARY", "TERTIARY" },
		TitleBox = TITLE_BOX,
		PanelSize = PALETTE_PANEL_SIZE,
		Help = 'Now it\'s time to begin creating your character! Most costumes have between 2-3 colors. I am using the term "Primary" to describe the most prominent color.',
		IsSlidingOut = true,
	},
	{
		Key = "Neon Elements",
		Kind = "Rows",
		IdentityKey = "Main",
		Titles = { "Neon Elements" },
		TitleBox = TITLE_BOX,
		PanelSize = PANEL_SIZE,
		Help = "Make your character glow! You have the ability to convert your primary, secondary, and tertiary into Neon Elements - use wisely!",
		Rows = NEON_ROWS,
		Forward = {
			Text = "Continue",
			Box = MIDDLE_FORWARD_BOX,
		},
	},
	{
		Key = "Abilities",
		Kind = "Rows",
		IdentityKey = "Main",
		Titles = { "Abilities" },
		TitleBox = TITLE_BOX,
		PanelSize = PANEL_SIZE,
		Help = "Now to turn your hero into a super hero! Choose a melee ability for fighting up-close, a ranged ability for those farther off, and a special ability to aide you in your battle!",
		Rows = ABILITY_ROWS,
		Forward = {
			Text = "Continue",
			Box = {
				Position = UDim2.fromScale(0.05, 0.875),
				Size = UDim2.fromScale(0.4, 0.1),
			},
		},
		Rent = {
			Position = UDim2.fromScale(0.55, 0.875),
			Size = UDim2.fromScale(0.4, 0.1),
		},
	},
	{
		Key = "Alignment",
		Kind = "Rows",
		IdentityKey = "Main",
		Titles = { "Alignment" },
		TitleBox = TITLE_BOX,
		PanelSize = PANEL_SIZE,
		Help = 'Now you get to choose your alignment! This allows people to know who\'s on their side. The only exception to this rule are the people in the "OTHER" category.',
		Rows = ALIGNMENT_ROWS,
		Forward = {
			Text = "Continue",
			Box = MIDDLE_FORWARD_BOX,
		},
	},
	{
		Key = "Naming",
		Kind = "Names",
		IdentityKey = "Main",
		Titles = { "Naming" },
		TitleBox = TITLE_BOX,
		PanelSize = PANEL_SIZE,
		Help = "Now you need to name your character! Like most superheroes, characters have a secret identity and a superhero name - time for you to decide yours!",
		Names = NAME_BARS,
		Test = {
			Text = "Test for Censorship",
			Box = {
				Position = UDim2.fromScale(0.2, 0.75),
				Size = UDim2.fromScale(0.6, 0.1),
			},
		},
		Forward = {
			Text = "Continue",
			Box = MIDDLE_FORWARD_BOX,
		},
	},
	{
		Key = "Mode",
		Kind = "Rows",
		IdentityKey = "Main",
		Titles = { "Mode" },
		TitleBox = TITLE_BOX,
		PanelSize = PANEL_SIZE,
		Help = "Choose PVP if you want to fight people for glory! Choose RP if you would rather live out your fantasies unbothered. That's all - you're done!",
		Rows = MODE_ROWS,
		Forward = {
			Text = "Enter",
			Box = MIDDLE_FORWARD_BOX,
		},
	},
}
-- Variables
-- References
-- Private Functions
local function deepFreeze(value: { [any]: any })
	for _, child in value do
		if type(child) == "table" and not table.isfrozen(child) then
			deepFreeze(child)
		end
	end
	table.freeze(value)
end
deepFreeze(PAGES)
-- Class
return table.freeze({
	PAGES = PAGES,
	-- the walk can only be given up on its first stops, the button under the pages says so until it's past them
	RESTART_STEP_COUNT = 2,
	RESTART_TEXT = "RESTART",
	BACK_TEXT = "BACK",
	BACK_POSITION = UDim2.fromScale(0.45, 0.9),
	BACK_SIZE = UDim2.fromScale(0.1, 0.08),
	-- the teal of a page that hides the booth, which is the teal of the booth
	COVER_COLOR = Color3.fromRGB(0, 143, 156),
	CARD_COLOR = Color3.new(1, 1, 1),
	-- what a cover says that isn't shouted, the one font of it no other screen of the game shares
	COVER_FONT = Font.new("rbxasset://fonts/families/Arial.json"),
	PANEL_TRANSPARENCY = 0.3,
	PANEL_POSITION = UDim2.fromScale(0.025, 0.125),
	HELP_PANEL_POSITION = UDim2.fromScale(0.675, 0.125),
	HELP_PANEL_SIZE = PANEL_SIZE,
	HELP_POSITION = UDim2.fromScale(0.1, 0.15),
	HELP_SIZE = UDim2.fromScale(0.8, 0.7),
	-- a row + what's on it: an arrow at each end, what it steps through in between
	ROW_SIZE = ROW_SIZE,
	ROW_LEFT_POSITION = UDim2.fromScale(0.05, 0.1),
	ROW_RIGHT_POSITION = UDim2.fromScale(0.85, 0.1),
	ROW_ARROW_SIZE = UDim2.fromScale(0.1, 0.8),
	ROW_NAME_POSITION = UDim2.fromScale(0.15, 0),
	ROW_NAME_SIZE = UDim2.fromScale(0.7, 1),
	-- how much of a row that hangs under another shows through
	NESTED_ROW_TRANSPARENCY = 0.5,
	-- the box under the row of the extras: what's tried on is named at its left, the button at its right keeps it or
	-- lets go of it
	EXTRAS_BOX_POSITION = UDim2.fromScale(NESTED_ROW_X, NESTED_ROW_Y),
	EXTRAS_BOX_SIZE = NESTED_ROW_SIZE,
	EXTRAS_LABEL_POSITION = UDim2.fromScale(0.15, 0),
	EXTRAS_LABEL_SIZE = UDim2.fromScale(0.7, 1),
	EXTRAS_BUTTON_POSITION = UDim2.fromScale(0.835, 0.1),
	EXTRAS_BUTTON_SIZE = UDim2.fromScale(0.15, 0.8),
	EXTRAS_ADD_TEXT = "Add",
	EXTRAS_REMOVE_TEXT = "Remove",
	-- what a row reads under it while it has no pick to name
	NONE_TEXT = "None",
	-- the power a row has picked is written under the row, nearly as high as the row is
	ASSIGNMENT_POSITION = UDim2.fromScale(0, 1),
	ASSIGNMENT_SIZE = UDim2.fromScale(1, 0.85),
	-- the box a name is typed in fills its bar but for a thin blue edge
	NAME_BOX_POSITION = UDim2.fromScale(0.025, 0.05),
	NAME_BOX_SIZE = UDim2.fromScale(0.95, 0.9),
	-- what the row of the mode reads for one who fights + for one who sat fights out
	MODE_TEXT = "PVP",
	PEACEFUL_MODE_TEXT = "RP",
	-- the grid: a white box that's square on a wide screen, 8 swatches a row with no gap between them
	GRID_POSITION = UDim2.fromScale(0.05, 0.17),
	GRID_SIZE = UDim2.fromScale(0.9, 0.8),
	GRID_COLUMN_COUNT = 8,
	SWATCH_COLORS = SWATCH_COLORS,
	-- what the button that isn't of use yet says + how much of it shows
	RENT_TEXT = "Rent",
	RENT_TRANSPARENCY = 0.5,
	-- what a row reads in place of its name while what it has on is held back from the player: behind a pass, which
	-- a press on it offers, or for the members of the group. the green is the one the old scripts ended up with
	GATE_PASS_TEXT = "Purchase Here!",
	GATE_GROUP_TEXT = "Group Members Only!",
	GATE_COLOR = Color3.fromRGB(0, 255, 0),
	-- how long a button says why it didn't do what it's for
	NOTICE_DURATION = 5,
	-- the bar the mannequin is turned with: it's under the screen until a page shows the booth, then it comes up
	-- + stays. its three buttons are laid out the way a row's are
	ROTATE_PARKED_POSITION = UDim2.fromScale(0.35, 1),
	ROTATE_POSITION = UDim2.fromScale(0.35, 0.8),
	ROTATE_SIZE = UDim2.fromScale(0.3, 0.07),
	ROTATE_TRANSPARENCY = 0.3,
	ROTATE_TEXT = "ROTATE",
	TURN_STEP_RAD = 0.7,
})
