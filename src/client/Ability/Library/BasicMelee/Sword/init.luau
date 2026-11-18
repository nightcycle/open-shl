--!strict
-- Services
-- Packages
-- Modules
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
local Sword = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/Sword")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(Sword, {
	DrawAnimation = "Sheathing",
	SwingAnimations = { "KnifeJab", "KnifeSlash" },
}):Build()
