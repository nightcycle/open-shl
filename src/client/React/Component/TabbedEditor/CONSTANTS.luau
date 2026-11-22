--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
local PowerType = require("@game/ReplicatedStorage/Shared/Type/Power")
local Types = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Component/TabbedEditor/Types")
type ArtInfo = Types.ArtInfo
type BarsInfo = Types.BarsInfo
type Box = Types.Box
type EntryInfo = Types.EntryInfo
type HeadingInfo = Types.HeadingInfo
type ListInfo = Types.ListInfo
type PowerGroup = PowerType.PowerGroup
type SwatchInfo = Types.SwatchInfo
type TabInfo = Types.TabInfo
type ToggleInfo = Types.ToggleInfo
-- Constants
local ART = Image["shl-3"].ui["suit-creation"]
local COMMON_ART = Image["shl-3"].ui.common
local WHITE = Color3.new(1, 1, 1)
-- the folders of the suit pieces, in the order the application button steps through them
local LIMBS: { string } = table.freeze({
	"Suit/Head",
	"Suit/Torso",
	"Suit/Left Arm",
	"Suit/Right Arm",
	"Suit/Left Leg",
	"Suit/Right Leg",
})
local SUIT_FOLDERS: { string } = table.freeze({
	"Suit/Head",
	"Suit/Torso",
	"Suit/Left Arm",
	"Suit/Right Arm",
	"Suit/Left Leg",
	"Suit/Right Leg",
	"Suit/Capes",
	"Suit/Extras",
})
-- Variables
-- References
-- Private Functions
-- a spot on the square canvas of a page
local function box(x: number, y: number, width: number, height: number): Box
	return table.freeze({
		Position = UDim2.fromScale(x, y),
		Size = UDim2.fromScale(width, height),
	})
end
local function art(image: string, x: number, y: number, width: number, height: number): ArtInfo
	return table.freeze({
		Image = image,
		Box = box(x, y, width, height),
	})
end
-- every heading tag is one size + sits at one x, however far down the page its heading is drawn
local function heading(text: string, y: number): HeadingInfo
	return table.freeze({
		Text = text,
		Box = box(0.325, y, 0.35, 0.042),
	})
end
-- Class
-- every page of the old editor was laid out by hand over a picture of its own, on a square canvas as tall as the
-- panel. the numbers below are where its controls ended up on that canvas
local TABS: { TabInfo } = {
	{
		Key = "Hair",
		Caption = "Hair",
		Icon = ART["menu-race-hair.png"],
		Art = ART["race-hair-background.png"],
		Sidebars = { art(COMMON_ART["sidebar-thin.png"], -0.4656, 0.097, 1.3419, 0.8439) },
		Headings = { heading("HAIR", 0.065) },
		Lists = {
			{ Box = box(0.1924, 0.1424, 0.551, 0.7645), Folders = { "Hair/Hair" } },
		} :: { ListInfo },
		Swatches = {
			{ Image = ART["skin-color.png"], Box = box(0.7586, 0.1767, 0.2008, 0.2008), Page = "Hair/Skin Color" },
			{ Image = ART["hair-color.png"], Box = box(0.7564, 0.537, 0.2008, 0.2008), Folders = { "Hair/Hair" } },
		} :: { SwatchInfo },
		-- the picture is how the skin + the hair color of the two stand, not what a press would make of them
		Toggles = {
			{
				Page = "Hair/Matching",
				Box = box(0.3722, 0.8093, 0.2546, 0.2546),
				-- the top of the square lies over the last rows of the list, the pill is drawn below that
				HitBox = box(0.05, 0.25, 0.9, 0.445),
				Image = ART["matching-separate.png"],
				SelectedImage = ART["matching-combine.png"],
			},
		} :: { ToggleInfo },
	},
	{
		Key = "Face",
		Caption = "Face",
		Icon = ART["menu-face.png"],
		Art = ART["face-background.png"],
		IdentityKey = "Secret",
		Sidebars = {
			art(COMMON_ART["sidebar.png"], -0.1057, 0.1147, 0.622, 0.366),
			art(COMMON_ART["sidebar.png"], -0.1057, 0.5868, 0.622, 0.3383),
		},
		Headings = { heading("EYES", 0.065), heading("MOUTHS", 0.544) },
		Lists = {
			{ Box = box(0.1924, 0.1308, 0.551, 0.3361), Folders = { "Face/Eyes" } },
			{ Box = box(0.1924, 0.6167, 0.551, 0.2981), Folders = { "Face/Mouths" } },
		} :: { ListInfo },
		Swatches = {
			{ Image = ART["eye-color.png"], Box = box(0.761, 0.2094, 0.1784, 0.1784), Folders = { "Face/Eyes" } },
		} :: { SwatchInfo },
	},
	{
		Key = "Clothing",
		Caption = "Clothing",
		Icon = ART["menu-shirt-pants.png"],
		Art = ART["shirt-pants-background.png"],
		IdentityKey = "Secret",
		Sidebars = {
			art(COMMON_ART["sidebar.png"], -0.0781, 0.1147, 0.5612, 0.402),
			art(COMMON_ART["sidebar.png"], -0.0781, 0.5661, 0.5612, 0.3578),
		},
		Headings = { heading("SHIRTS", 0.065), heading("PANTS", 0.544) },
		Lists = {
			{ Box = box(0.1924, 0.1263, 0.551, 0.3406), Folders = { "Clothing/Shirts" } },
			{ Box = box(0.1924, 0.619, 0.551, 0.2981), Folders = { "Clothing/Pants" } },
		} :: { ListInfo },
		Swatches = {
			{
				Image = ART["shirt-primary-color.png"],
				Box = box(0.7819, 0.137, 0.136, 0.136),
				Folders = { "Clothing/Shirts" },
				Group = "Primary",
			},
			{
				Image = ART["shirt-secondary-color.png"],
				Box = box(0.7822, 0.2993, 0.136, 0.136),
				Folders = { "Clothing/Shirts" },
				Group = "Secondary",
			},
			{
				Image = ART["pants-primary-color.png"],
				Box = box(0.7819, 0.612, 0.136, 0.136),
				Folders = { "Clothing/Pants" },
				Group = "Primary",
			},
			{
				Image = ART["pants-secondary-color.png"],
				Box = box(0.7822, 0.7743, 0.136, 0.136),
				Folders = { "Clothing/Pants" },
				Group = "Secondary",
			},
		} :: { SwatchInfo },
	},
	{
		Key = "Accessories",
		Caption = "Accessories",
		Icon = ART["menu-accessories.png"],
		Art = ART["accessories-background.png"],
		IdentityKey = "Secret",
		Sidebars = {
			art(ART["accessories-sidebar.png"], 0.0427, 0.1069, 0.32, 0.2),
			art(ART["accessories-sidebar.png"], 0.0427, 0.4132, 0.32, 0.2184),
			art(ART["accessories-sidebar.png"], 0.0427, 0.6942, 0.32, 0.2319),
		},
		Headings = { heading("ACCESSORIES", 0.065), heading("HATS", 0.367), heading("GLASSES", 0.664) },
		Lists = {
			{ Box = box(0.1919, 0.1266, 0.551, 0.1613), Folders = { "Accessories/Facial Hair" } },
			{ Box = box(0.1919, 0.4238, 0.551, 0.1579), Folders = { "Accessories/Hats" } },
			{ Box = box(0.1919, 0.7234, 0.551, 0.1918), Folders = { "Accessories/Glasses" } },
		} :: { ListInfo },
	},
	{
		Key = "Size",
		Caption = "Size",
		Icon = ART["menu-size-name.png"],
		Art = ART["size-name-background.png"],
		-- the art calls the width a weight
		Headings = { heading("HEIGHT", 0.065), heading("WEIGHT", 0.364), heading("IDENTITY", 0.664) },
		Bars = {
			{
				Page = "Size/Body",
				Axis = "Height",
				Boxes = {
					box(0.3123, 0.2219, 0.0654, 0.0331),
					box(0.385, 0.2073, 0.0682, 0.0472),
					box(0.4606, 0.1877, 0.0682, 0.0668),
					box(0.5385, 0.1704, 0.0682, 0.0841),
					box(0.6182, 0.1498, 0.0729, 0.1047),
				},
			},
			{
				Page = "Size/Body",
				Axis = "Width",
				Boxes = {
					box(0.3123, 0.5149, 0.0654, 0.0331),
					box(0.385, 0.5002, 0.0682, 0.0472),
					box(0.4606, 0.4808, 0.0682, 0.0668),
					box(0.5385, 0.4634, 0.0682, 0.0841),
					box(0.6182, 0.4427, 0.0729, 0.1047),
				},
			},
		} :: { BarsInfo },
		-- the pill of the everyday name is drawn above the one of the hero's
		Entries = {
			{
				Page = "Size/Name",
				Box = box(0.3096, 0.7531, 0.378, 0.035),
				IdentityKey = "Secret",
				TextColor3 = WHITE,
				PlaceholderColor3 = WHITE,
			},
			{
				Page = "Size/Name",
				Box = box(0.3096, 0.848, 0.378, 0.035),
				IdentityKey = "Main",
				TextColor3 = WHITE,
				PlaceholderColor3 = WHITE,
			},
		} :: { EntryInfo },
	},
	{
		Key = "Suit",
		Caption = "Suit",
		Icon = ART["menu-suit-cape.png"],
		Art = ART["suit-cape-background.png"],
		IdentityKey = "Main",
		Sidebars = {
			art(COMMON_ART["sidebar.png"], -0.0781, 0.1147, 0.5612, 0.4001),
			art(COMMON_ART["sidebar.png"], -0.0781, 0.5799, 0.5612, 0.3439),
		},
		Headings = {
			heading("SUITS", 0.065),
			-- the art has the capes under a heading of their own, its tag is a shade off the others
			{ Text = "ACCESSORIES", Box = box(0.375, 0.5503, 0.25, 0.0547), TextColor3 = Color3.fromRGB(42, 174, 232) },
		},
		Lists = {
			{ Box = box(0.1924, 0.1308, 0.551, 0.3361), Limbs = LIMBS },
			{ Box = box(0.1924, 0.6167, 0.551, 0.2983), Folders = { "Suit/Capes", "Suit/Extras" } },
		} :: { ListInfo },
		Swatches = {
			{
				Image = ART["suit-primary-color.png"],
				Box = box(0.761, 0.1894, 0.1784, 0.1784),
				Folders = SUIT_FOLDERS,
				Group = "Primary",
			},
			{
				Image = ART["suit-secondary-color.png"],
				Box = box(0.7608, 0.4348, 0.1784, 0.1784),
				Folders = SUIT_FOLDERS,
				Group = "Secondary",
			},
			{
				Image = ART["suit-base-color.png"],
				Box = box(0.7608, 0.6828, 0.1784, 0.1784),
				Folders = SUIT_FOLDERS,
				Group = "Tertiary",
			},
		} :: { SwatchInfo },
		-- it hangs under the canvas, the strip of its art is the bottom of a square as wide as itself
		Application = {
			Art = art(COMMON_ART["label.png"], 0.2, 0.795, 0.6, 0.6),
			Box = box(0.1999, 1.0204, 0.6, 0.0869),
		},
	},
	{
		Key = "Emblem",
		Caption = "Emblem",
		Icon = ART["menu-emblem.png"],
		Art = ART["emblem-background.png"],
		IdentityKey = "Main",
		Sidebars = { art(COMMON_ART["sidebar-thin.png"], -0.4656, 0.097, 1.3419, 0.8439) },
		Headings = { heading("EMBLEMS", 0.065) },
		Lists = {
			{ Box = box(0.1924, 0.1424, 0.551, 0.7645), Folders = { "Emblem" } },
		} :: { ListInfo },
		Swatches = {
			{
				Image = ART["emblem-primary-color.png"],
				Box = box(0.7447, 0.2642, 0.2008, 0.2008),
				Folders = { "Emblem" },
				Group = "Primary",
			},
			{
				Image = ART["emblem-secondary-color.png"],
				Box = box(0.7426, 0.5163, 0.2008, 0.2008),
				Folders = { "Emblem" },
				Group = "Secondary",
			},
		} :: { SwatchInfo },
	},
	{
		Key = "Powers",
		Caption = "Powers",
		Icon = ART["menu-powers.png"],
		Art = ART["powers-background.png"],
		Path = "Powers",
		Sidebars = {
			art(COMMON_ART["sidebar.png"], -0.0781, 0.1147, 0.5612, 0.2877),
			art(COMMON_ART["sidebar.png"], -0.0781, 0.4855, 0.5612, 0.2978),
		},
		Headings = { heading("ATTACKS", 0.065), heading("EFFECTS", 0.449) },
		Lists = {
			{ Box = box(0.1924, 0.1308, 0.551, 0.244), PowerGroups = { "basic-melee", "ranged" } :: { PowerGroup } },
			{
				Box = box(0.1919, 0.5112, 0.551, 0.2528),
				PowerGroups = { "transportation", "special" } :: { PowerGroup },
			},
		} :: { ListInfo },
		Slots = {
			Box = box(0.1611, 0.7833, 0.6777, 0.1422),
			SlotSize = 0.12,
			Padding = 0.04,
		},
	},
	{
		Key = "Backstory",
		Caption = "Backstory",
		Icon = ART["menu-team-story.png"],
		Art = ART["team-story-background.png"],
		Headings = { heading("BACKSTORY", 0.065) },
		Entries = {
			{
				Page = "Backstory",
				Box = box(0.2672, 0.1869, 0.4816, 0.3279),
				TextSize = 18,
				TextColor3 = Color3.fromRGB(72, 72, 72),
				PlaceholderColor3 = Color3.fromRGB(199, 199, 199),
			},
		} :: { EntryInfo },
		Logo = art(ART["team-story-logo.png"], 0.3187, 0.585, 0.3302, 0.3302),
	},
}
return {
	TABS = TABS,
	-- the last button of the column isn't a page, it saves + leaves
	DONE_ICON = ART["menu-done.png"],
	DONE_CAPTION = "Complete",
	-- a press on a tab isn't taken until the page of the one before has had the time to fold away
	TAB_LOCK_DURATION = 0.65,
	-- the column hugs the right edge, 20 px off it
	TAB_PANEL_ANCHOR_POINT = Vector2.new(1, 0.5),
	TAB_PANEL_POSITION = UDim2.new(1, -20, 0.5, 0),
	TAB_PANEL_SIZE = UDim2.fromScale(0.06, 0.8),
	-- a button is square, in heights of the column
	TAB_SIZE = 0.09,
	TAB_PADDING = 0.012,
	-- the caption reaches out of its button to the left
	TAB_CAPTION_POSITION = UDim2.fromScale(-0.1, 0.5),
	TAB_CAPTION_SIZE = UDim2.fromScale(3, 0.5),
	TAB_CAPTION_TEXT_SIZE = 14,
	-- the panel is anchored off its left so the margin of the art hangs off the screen, the canvas of a page is the
	-- square at its left that's as tall as it
	PANEL_ANCHOR_POINT = Vector2.new(0.18, 0.5),
	PANEL_POSITION = UDim2.new(0, 20, 0.45, 0),
	PANEL_SIZE = UDim2.fromScale(0.4, 0.8),
	-- the art of a page sits a hair above its canvas
	PAGE_ART_BOX = box(0, -0.0022, 1, 1),

	-- a row is as tall on every screen, the pill of its art is the middle band of a square seven rows tall
	ROW_HEIGHT = 25,
	ROW_STEP = 27,
	ROW_WIDTH = 0.977,
	ROW_ART = COMMON_ART["button-template.png"],
	ROW_ART_HEIGHT = 7,
	ROW_TEXT_SIZE = UDim2.fromScale(0.85, 0.6),
	ROW_TEXT_COLOR = Color3.fromRGB(122, 122, 122),
	-- the rows clear the scroll bar, which rides on a track drawn at the left of the list
	LIST_PADDING = 0.13,
	LIST_SCROLL_BAR_WIDTH = 0.05,
	-- the bar the lists had is an image of the place that can't be fetched, this one is the shop's
	LIST_SCROLL_BAR_IMAGE = Image["shl-3"].ui.shop["scroll-bar.png"],

	SLOT_ART = ART["power-slot.png"],
	SLOT_ART_SIZE = 1.3,
	-- a slot the player has no pass for
	LOCKED_SLOT_COLOR = Color3.fromRGB(111, 111, 111),
	LOCKED_SLOT_TRANSPARENCY = 0.5,

	APPLICATION_TEXT_SIZE = 30,
	APPLICATION_TEXT_COLOR = Color3.fromRGB(144, 144, 144),

	-- both mannequins are turned by the half of the stage that's pressed
	STAGE_ANCHOR_POINT = Vector2.new(0, 0.5),
	STAGE_POSITION = UDim2.fromScale(0.3345, 0.5),
	STAGE_SIZE = UDim2.fromScale(0.5992, 0.8),
	TURN_STEP_DEG = 45,
	TURN_DURATION = 0.5,
	-- the camera looks past the mannequin in front so the pair stands clear of the panel. the anchors sit on the floor,
	-- the point it used to aim for was that far off the middle of a body
	CAMERA_TARGET_OFFSET = Vector3.new(2, 3.1, 0),
	-- the old camera never moved, which left the head of the tallest body out of the picture. this one backs off a
	-- body + looks higher up by half of what the body is taller than the plain one, + comes as much closer to a
	-- shorter one: all of it would draw every body the same size
	CAMERA_FOLLOW = 0.5,
	-- how long it takes to get to a new framing, at a steady pace
	CAMERA_DURATION = 0.75,

	-- the roll button runs at this size under the mannequins, whatever the file it came from says
	RANDOMIZE_ANCHOR_POINT = Vector2.new(0.5, 1),
	RANDOMIZE_POSITION = UDim2.new(0.575, 20, 1, -20),
	RANDOMIZE_SIZE = UDim2.fromOffset(150, 40),
	RANDOMIZE_TEXT_COLOR = Color3.fromRGB(131, 131, 131),
	BUTTON_ART = COMMON_ART["button-template.png"],
	-- a save that's turned down is said over the roll button, the old editor had no words for it
	ERROR_ANCHOR_POINT = Vector2.new(0.5, 1),
	ERROR_POSITION = UDim2.new(0.575, 20, 1, -70),
	ERROR_SIZE = UDim2.fromOffset(400, 40),

	PICKER = {
		ART = ART["color-picker-color-background.png"],
		HEADING = heading("PROPERTIES", 0.065),
		-- the art has five outlines where the recent colors go, the row draws its own
		COVER_BOX = box(0.3513, 0.7332, 0.3156, 0.0501),
		COVER_COLOR = Color3.fromRGB(232, 232, 232),
		-- the label names what the switch leads to, not what's shown
		SWITCH_BOX = box(0.2, 0.135, 0.6, 0.1),
		SWITCH_ART_BOX = box(0.2, -0.115, 0.6, 0.6),
		SWITCH_TAG_BOX = box(0.26, 0.155, 0.48, 0.06),
		SWITCH_TAG_COLOR = Color3.fromRGB(57, 187, 234),
		COLORS_ART = ART["color-picker-colors-label.png"],
		COLORS_TEXT = "COLORS",
		PATTERNS_ART = ART["color-picker-textures-label.png"],
		PATTERNS_TEXT = "TEXTURES",
		TAG_TEXT_COLOR = Color3.fromRGB(251, 253, 255),
		-- the strip picks the hue, the square how pale + how dark it is
		HUE_BOX = box(0.214, 0.2525, 0.0453, 0.469),
		HUE_IMAGE = ART["color-picker-hue.png"],
		SHADE_BOX = box(0.316, 0.2525, 0.469, 0.469),
		SHADE_IMAGE = ART["color-picker-saturation-value.png"],
		-- a pick lands on the hundredth it's in
		STEPS = 100,
		-- the patterns take the place of both, a fifth of it each with four to a row
		GRID_BOX = box(0.214, 0.2525, 0.5708, 0.469),
		GRID_CELL_SIZE = UDim2.fromScale(0.2, 0.2),
		GRID_CELL_PADDING = UDim2.fromScale(0.05, 0.05),
		GRID_COLUMNS = 4,
		RECENT_BOX = box(0.1, 0.74, 0.8, 0.07),
		RECENT_SIZE = 0.8,
		RECENT_PADDING = 0.025,
		RECENT_COUNT = 10,
		RECENT_BORDER_COLOR = Color3.fromRGB(221, 221, 221),
		RECENT_BORDER_SIZE = 3,
		DONE_BOX = box(0.2899, 0.8225, 0.42, 0.105),
		DONE_ART = ART["color-picker-pick-label.png"],
		DONE_ART_BOX = box(0.2899, 0.665, 0.42, 0.42),
		DONE_TAG_BOX = box(0.311, 0.8435, 0.378, 0.063),
		DONE_TEXT = "SELECT",
	},
}
