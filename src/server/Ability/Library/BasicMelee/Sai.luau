--!strict
-- Services
-- Packages
-- Modules
local MeleeFactory = require("@game/ServerScriptService/Server/Ability/Factory/Melee")
local Sai = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/Sai")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(Sai):Build()
