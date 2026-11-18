--!strict
-- Services
-- Packages
-- Modules
local LaserHand = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/LaserHand")
local ShotFactory = require("@game/ServerScriptService/Server/Ability/Factory/Shot")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new(LaserHand):Build()
