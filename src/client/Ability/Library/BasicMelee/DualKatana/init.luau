--!strict
-- Services
-- Packages
-- Modules
local DualKatana = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/DualKatana")
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(DualKatana, {
	DrawAnimation = "ClawSheathing",
	SwingAnimations = { "LeftSlash", "RightSlash" },
}):Build()
