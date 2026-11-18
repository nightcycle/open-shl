--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
type ImageGroup = { [string]: any }
-- Constants
-- every folder of asset/image that isn't another game's. a new one is loaded ahead once it's listed here
local IMAGE_GROUPS: { ImageGroup } = {
	Image.art,
	Image["captain-coolguy"],
	Image.face,
	Image.fx,
	Image.material,
	Image.mesh,
	Image.tools,
	Image.ui,
}
table.freeze(IMAGE_GROUPS)
-- Variables
-- References
-- Private Functions
-- Class
return IMAGE_GROUPS
