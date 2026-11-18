--!strict
-- Services
-- Packages
-- Modules
local Hammer = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/Hammer")
local MeleeFactory = require("@game/ServerScriptService/Server/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(Hammer):Build()
