--!strict
-- Services
-- Packages
-- Modules
local LaserEyes = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/LaserEyes")
local ShotFactory = require("@game/ServerScriptService/Server/Ability/Factory/Shot")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new(LaserEyes):Build()
