--!strict
-- Services
-- Packages
-- Modules
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
-- Types
local ServerType = require("@game/ReplicatedStorage/Shared/Type/Server")
type Mode = ServerType.Mode
export type Card = {
	Mode: Mode,
	Title: string,
	Description: string,
}
-- Constants
-- the places of the game somebody can go over to from this one, in the words of the old place. it only ever led one
-- way: the roleplay place had its panel open on an empty list, so there's nothing to open here + no button for it
local CARDS: { Card } = {}
if BUILD_CONFIG.MODE == "combat" then
	table.insert(
		CARDS,
		table.freeze({
			Mode = "roleplay" :: Mode,
			Title = "Roleplay Mode",
			Description = "Tired of getting killed while roleplaying with friends? Roleplay mode is your answer!",
		})
	)
end
table.freeze(CARDS)
-- Variables
-- References
-- Private Functions
-- Class
return CARDS
