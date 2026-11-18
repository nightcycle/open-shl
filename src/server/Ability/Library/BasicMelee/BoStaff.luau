--!strict
-- Services
-- Packages
-- Modules
local BoStaff = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/BoStaff")
local MeleeFactory = require("@game/ServerScriptService/Server/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(BoStaff):Build()
