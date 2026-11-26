--!strict
-- Services
-- Packages
-- Modules
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
local Sai = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/Sai")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- they come out without a flourish + are swung the way two blades are
return MeleeFactory.new(Sai, {
	SwingAnimations = { "LeftSlash", "RightSlash" },
}):Build()
