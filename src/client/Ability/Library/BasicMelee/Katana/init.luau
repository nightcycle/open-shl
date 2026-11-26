--!strict
-- Services
-- Packages
-- Modules
local Katana = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/Katana")
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- it comes out without a flourish + is swung from one side or the other
return MeleeFactory.new(Katana, {
	SwingAnimations = { "RightSlash", "LeftSlash" },
}):Build()
