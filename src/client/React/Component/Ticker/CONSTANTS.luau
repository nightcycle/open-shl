--!strict
-- Services
-- Packages
-- Modules
-- Types
-- Constants
-- the bar along the top of the screen, a twentieth of its height
local BAR_SIZE = UDim2.fromScale(1, 0.05)
local BAR_COLOR = Color3.new(0, 0, 0)
-- how long the bar is empty before every message + how long one is read for. nothing ever scrolled across it
local GAP_DURATION = 1
local HOLD_DURATION = 7
-- what the old place read out in turn, word for word: its news of 2016
local MESSAGES: { string } = table.freeze({
	"Follow me on twitter @BroRubik for updates on my games!",
	"Turn down your graphics quality if you experience lag!",
	"Press Menu, it has cool things",
	"SHL may recieve small edits and fixes until SHL II is out",
	"SHL II is confirmed. Development starts December 1st",
	"Send all SHL II ideas to the forum linked in the game description!",
})
-- Variables
-- References
-- Private Functions
-- Class
return table.freeze({
	BAR_SIZE = BAR_SIZE,
	BAR_COLOR = BAR_COLOR,
	GAP_DURATION = GAP_DURATION,
	HOLD_DURATION = HOLD_DURATION,
	MESSAGES = MESSAGES,
})
