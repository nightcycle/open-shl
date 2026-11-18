--!strict
-- Services
-- Packages
-- Modules
local JungleKnife = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/JungleKnife")
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(JungleKnife, {
	DrawAnimation = "Sheathing",
	SwingAnimations = { "KnifeJab", "KnifeSlash" },
}):Build()
