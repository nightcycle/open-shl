--!strict
-- Services
-- Packages
-- Modules
local Claws = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/Claws")
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(Claws, {
	SwingAnimations = { "LeftSlash", "RightSlash" },
}):Build()
