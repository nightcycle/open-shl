--!strict
-- Services
-- Packages
-- Modules
local MartialArts = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/MartialArts")
local MeleeFactory = require("@game/ServerScriptService/Server/Ability/Factory/Melee")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(MartialArts):Build()
