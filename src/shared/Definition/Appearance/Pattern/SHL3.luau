--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type PatternDefinition = AppearanceType.PatternDefinition
-- Constants
-- each is one image stretched over every face of a part + drawn in the color of its texture group
local PATTERNS: { PatternDefinition } = table.freeze({
	table.freeze({ Key = "camouflage", Name = "Camouflage", Image = Image["shl-3"].pattern["camouflage.png"] }),
	table.freeze({ Key = "leopard", Name = "Leopard", Image = Image["shl-3"].pattern["leopard.png"] }),
	table.freeze({ Key = "scales", Name = "Scales", Image = Image["shl-3"].pattern["scales.png"] }),
	table.freeze({ Key = "leather", Name = "Leather", Image = Image["shl-3"].pattern["leather.png"] }),
	table.freeze({ Key = "pinstriped", Name = "Pinstriped", Image = Image["shl-3"].pattern["pinstriped.png"] }),
	table.freeze({ Key = "fur", Name = "Fur", Image = Image["shl-3"].pattern["fur.png"] }),
	table.freeze({ Key = "honeycomb", Name = "Honeycomb", Image = Image["shl-3"].pattern["honeycomb.png"] }),
	table.freeze({ Key = "circuits", Name = "Circuits", Image = Image["shl-3"].pattern["circuits.png"] }),
})
-- Variables
-- References
-- Private Functions
-- Class
return PATTERNS
