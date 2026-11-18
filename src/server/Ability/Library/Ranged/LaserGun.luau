--!strict
-- Services
-- Packages
-- Modules
local GunFactory = require("@game/ServerScriptService/Server/Ability/Factory/Gun")
local LaserGun = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/LaserGun")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return GunFactory.new(LaserGun):Build()
