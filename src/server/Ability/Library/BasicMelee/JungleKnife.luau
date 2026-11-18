--!strict
-- Services
-- Packages
-- Modules
local JungleKnife = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/JungleKnife")
local MeleeFactory = require("@game/ServerScriptService/Server/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(JungleKnife):Build()
