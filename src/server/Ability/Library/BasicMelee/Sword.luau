--!strict
-- Services
-- Packages
-- Modules
local MeleeFactory = require("@game/ServerScriptService/Server/Ability/Factory/Melee")
local Sword = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/Sword")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(Sword):Build()
