--!strict
-- Services
-- Packages
-- Modules
local LaserVision = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/LaserVision")
local RayFactory = require("@game/ServerScriptService/Server/Ability/Factory/Ray")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return RayFactory.new(LaserVision):Build()
