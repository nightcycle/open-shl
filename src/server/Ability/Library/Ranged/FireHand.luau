--!strict
-- Services
-- Packages
-- Modules
local FireHand = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/FireHand")
local ShotFactory = require("@game/ServerScriptService/Server/Ability/Factory/Shot")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new(FireHand):Build()
