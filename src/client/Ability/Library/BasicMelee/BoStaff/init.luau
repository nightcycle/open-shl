--!strict
-- Services
-- Packages
-- Modules
local BoStaff = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/BoStaff")
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(BoStaff, {
	DrawAnimation = "Sheathing",
	SwingAnimations = { "KnifeJab", "KnifeSlash" },
}):Build()
