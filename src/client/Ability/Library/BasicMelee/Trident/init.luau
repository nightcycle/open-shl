--!strict
-- Services
-- Packages
-- Modules
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
local Trident = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/Trident")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(Trident, {
	DrawAnimation = "Sheathing",
	SwingAnimations = { "KnifeJab" },
}):Build()
