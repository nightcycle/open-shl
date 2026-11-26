--!strict
-- Services
-- Packages
-- Modules
local Katana = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/Katana")
local MeleeFactory = require("@game/ServerScriptService/Server/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(Katana):Build()
