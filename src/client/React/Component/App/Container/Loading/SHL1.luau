--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
type ImageGroup = { [string]: any }
-- Constants
-- its own folders (asset/image/shl-1) that a screen or a face draws from: the logo it loads under, the cursors of its
-- tools + its 13 faces. the gags of its flats are on the map, which loads them by itself. the one texture a power of
-- its has waits until that power draws it
local IMAGE_GROUPS: { ImageGroup } = {
	Image["shl-1"].face,
	Image["shl-1"].ui,
}
table.freeze(IMAGE_GROUPS)
-- Variables
-- References
-- Private Functions
-- Class
return IMAGE_GROUPS
