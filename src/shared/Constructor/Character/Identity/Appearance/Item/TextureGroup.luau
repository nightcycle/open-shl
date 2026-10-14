--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
export type TextureGroup = AppearanceType.TextureGroup
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}
Module.new = function(color: Color3, material: Enum.Material?, transparency: number?): TextureGroup
	local out: TextureGroup = {
		Color = color,
		Material = material or Enum.Material.SmoothPlastic,
		Transparency = transparency or 0,
	}
	TableUtil.deepFreeze(out)
	return out
end

return Module
