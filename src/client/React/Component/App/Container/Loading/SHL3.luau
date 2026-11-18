--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
type ImageGroup = { [string]: any }
-- Constants
-- its own folders of asset/image that a screen, a face, a suit or a power draws from. its billboards + posters are on
-- the map, which loads them by itself. the effects wait until a power of its draws one
local IMAGE_GROUPS: { ImageGroup } = {
	Image.shl3.face,
	Image.shl3.pattern,
	Image.shl3.tools,
	Image.shl3.ui,
	-- the one picture of the old kit a screen of its still hangs up: the exit on the corner of the shop
	{
		["exit.png"] = Image.ui["exit.png"],
	},
}
table.freeze(IMAGE_GROUPS)
-- Variables
-- References
-- Private Functions
-- Class
return IMAGE_GROUPS
