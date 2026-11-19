--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
type ImageGroup = { [string]: any }
-- Constants
-- every folder of its own (asset/image/shl-2) + the ones of core it draws from, core being what more than one game
-- has a use for. a new one is loaded ahead once it's listed here
local IMAGE_GROUPS: { ImageGroup } = {
	Image["shl-2"].art,
	Image["shl-2"]["captain-coolguy"],
	Image["shl-2"].face,
	Image["shl-2"].fx,
	Image["shl-2"].material,
	Image["shl-2"].mesh,
	Image["shl-2"].tools,
	Image["shl-2"].ui,
	Image.core.ui,
}
table.freeze(IMAGE_GROUPS)
-- Variables
-- References
-- Private Functions
-- Class
return IMAGE_GROUPS
