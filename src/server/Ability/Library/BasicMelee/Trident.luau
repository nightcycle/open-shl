--!strict
-- Services
-- Packages
-- Modules
local MeleeFactory = require("@game/ServerScriptService/Server/Ability/Factory/Melee")
local Trident = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/Trident")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(Trident):Build()
