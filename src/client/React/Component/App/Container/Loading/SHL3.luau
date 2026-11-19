--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
type ImageGroup = { [string]: any }
-- Constants
-- its own folders (asset/image/shl-3) that a screen, a face, a suit or a power draws from. its billboards + posters
-- are on the map, which loads them by itself. the effects wait until a power of its draws one
local IMAGE_GROUPS: { ImageGroup } = {
	Image["shl-3"].face,
	Image["shl-3"].pattern,
	Image["shl-3"].tools,
	Image["shl-3"].ui,
	-- the one picture of core a screen of its hangs up: the exit on the corner of the shop
	{
		["exit.png"] = Image.core.ui["exit.png"],
	},
}
table.freeze(IMAGE_GROUPS)
-- Variables
-- References
-- Private Functions
-- Class
return IMAGE_GROUPS
