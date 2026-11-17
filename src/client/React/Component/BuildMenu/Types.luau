--!strict
-- Services
-- Packages
-- Modules
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
export type FurnitureDefinition = BaseType.FurnitureDefinition
export type FurnitureCategory = BaseType.FurnitureCategory
export type ThemeDefinition = BaseType.ThemeDefinition
export type Category = FurnitureCategory | "Theme"
-- Active is the furniture the pointer places + the theme the base wears
export type CardState = "ForSale" | "Purchasing" | "Owned" | "Active"
-- a new one for every request that's turned down, so the same line said twice still starts over
export type Refusal = {
	Message: string,
	-- the furniture or theme that wasn't sold, its card flashes
	Id: string?,
}
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return {}
