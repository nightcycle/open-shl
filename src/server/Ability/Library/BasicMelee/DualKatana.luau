--!strict
-- Services
-- Packages
-- Modules
local DualKatana = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/DualKatana")
local MeleeFactory = require("@game/ServerScriptService/Server/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(DualKatana):Build()
