--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
type ImageGroup = { [string]: any }
-- Constants
-- its own folders of asset/image that a screen, a face, a suit or a power draws from + the effects every game shares.
-- its billboards + posters are on the map, which loads them by itself
local IMAGE_GROUPS: { ImageGroup } = {
	Image.fx,
	Image.shl3.face,
	Image.shl3.fx,
	Image.shl3.pattern,
	Image.shl3.tools,
	Image.shl3.ui,
}
table.freeze(IMAGE_GROUPS)
-- Variables
-- References
-- Private Functions
-- Class
return IMAGE_GROUPS
