--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- every number in here is the old place's, in scale of the screen or of the box that holds it: the page it asked
-- "new or load" on before a character was made, + the panel it kept the same five rows on while one was played
return table.freeze({
	-- the teal of every page that fills the screen
	PAGE_COLOR = Color3.fromRGB(0, 143, 156),
	CARD_COLOR = Color3.new(1, 1, 1),
	-- what loads a row from the page, the one on the panel is the blue the balance stands on
	LIST_LOAD_COLOR = Color3.fromRGB(170, 170, 255),

	NEW_POSITION = UDim2.fromScale(0.1, 0.45),
	LOAD_SUIT_POSITION = UDim2.fromScale(0.6, 0.45),
	CHOICE_SIZE = UDim2.fromScale(0.3, 0.1),
	-- the two buttons leave to the left as the list is put up, the list waits + leaves at the right
	CHOICE_AWAY_POSITION = UDim2.fromScale(-1, 0),
	LIST_PARKED_POSITION = UDim2.fromScale(1, 0),

	-- the list of the page is twice as wide as the panel that's opened over the game
	LIST_POSITION = UDim2.fromScale(0.1, 0.1),
	LIST_SIZE = UDim2.fromScale(0.8, 0.75),
	PANEL_POSITION = UDim2.fromScale(0.3, 0.1),
	PANEL_SIZE = UDim2.fromScale(0.4, 0.75),

	-- a row + the gap under it, five of them end where the note starts
	ROW_SIZE = UDim2.fromScale(1, 0.12),
	ROW_PITCH = 0.13,
	NAME_SIZE = UDim2.fromScale(0.525, 1),
	LIST_LOAD_POSITION = UDim2.fromScale(0.675, 0.1),
	SAVE_POSITION = UDim2.fromScale(0.55, 0.1),
	LOAD_POSITION = UDim2.fromScale(0.775, 0.1),
	BUTTON_SIZE = UDim2.fromScale(0.2, 0.8),
	-- a button that can't be used is half there, its word as well
	DEAD_TRANSPARENCY = 0.5,

	NOTE_POSITION = UDim2.fromScale(0, 0.66),
	NOTE_SIZE = UDim2.fromScale(1, 0.15),
	BACK_POSITION = UDim2.fromScale(0.3, 0.79),
	EXIT_POSITION = UDim2.fromScale(0.3, 0.85),
	LEAVE_SIZE = UDim2.fromScale(0.4, 0.12),

	NEW_TEXT = "NEW SUIT",
	LOAD_SUIT_TEXT = "LOAD SUIT",
	EMPTY_TEXT = "EMPTY",
	LOAD_TEXT = "LOAD",
	SAVE_TEXT = "SAVE",
	SAVING_TEXT = "Saving...",
	BACK_TEXT = "BACK",
	EXIT_TEXT = "EXIT",
	-- the old place never had to ask: a new suit of it was nobody's until it was saved over a row
	REPLACE_TEXT = "REPLACE",
	REPLACE_NOTE_TEXT = "Every row holds a suit: pick the one the new suit replaces",
})
