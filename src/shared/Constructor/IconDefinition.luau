--!strict
-- Services
-- Packages
-- Modules
-- Types
local MiscType = require("@game/ReplicatedStorage/Shared/Type/Misc")
export type IconDefinition = MiscType.IconDefinition
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

function Module.decal(assetIdOrUrl: number | string): IconDefinition
	local url = if type(assetIdOrUrl) == "string" then assetIdOrUrl else `rbxassetid://{assetIdOrUrl}`
	local out: IconDefinition = {
		Type = "Decal",
		Url = url,
	}
	table.freeze(out)
	assert(MiscType.IconDefinition(out))
	return out
end

function Module.sprite(sheetIdOrUrl: number | string, position: Vector2, size: Vector2): IconDefinition
	local url = if type(sheetIdOrUrl) == "string" then sheetIdOrUrl else `rbxassetid://{sheetIdOrUrl}`
	local out: IconDefinition = {
		Type = "Sprite",
		SheetUrl = url,
		Position = position,
		Size = size,
	}
	table.freeze(out)
	assert(MiscType.IconDefinition(out))
	return out
end

return Module
