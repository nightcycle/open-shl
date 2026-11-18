--!strict
-- Services
-- Packages
-- Modules
local GunFactory = require("@game/ServerScriptService/Server/Ability/Factory/Gun")
local Handgun = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/Handgun")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return GunFactory.new(Handgun):Build()
