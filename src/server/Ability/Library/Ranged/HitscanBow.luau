--!strict
-- Services
-- Packages
-- Modules
local HitscanBow = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/HitscanBow")
local RayFactory = require("@game/ServerScriptService/Server/Ability/Factory/Ray")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return RayFactory.new(HitscanBow):Build()
