--!strict
-- Services
-- Packages
-- Modules
local LightningHand = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/LightningHand")
local ShotFactory = require("@game/ServerScriptService/Server/Ability/Factory/Shot")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new(LightningHand):Build()
