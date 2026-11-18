--!strict
-- Services
-- Packages
-- Modules
local Hammer = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/Hammer")
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(Hammer, {
	DrawAnimation = "Sheathing",
	SwingAnimations = { "KnifeJab", "KnifeSlash" },
}):Build()
