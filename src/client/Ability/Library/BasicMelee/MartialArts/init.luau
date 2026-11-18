--!strict
-- Services
-- Packages
-- Modules
local MartialArts = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/MartialArts")
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(MartialArts, {
	SwingAnimations = { "PowerPunch", "Strike", "RightFootKick" },
	IsRooted = true,
}):Build()
