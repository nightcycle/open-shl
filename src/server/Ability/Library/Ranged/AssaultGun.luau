--!strict
-- Services
-- Packages
-- Modules
local AssaultGun = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/AssaultGun")
local GunFactory = require("@game/ServerScriptService/Server/Ability/Factory/Gun")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return GunFactory.new(AssaultGun):Build()
