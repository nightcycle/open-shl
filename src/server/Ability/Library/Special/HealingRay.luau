--!strict
-- Services
-- Packages
-- Modules
local HealingRay = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/HealingRay")
local RayFactory = require("@game/ServerScriptService/Server/Ability/Factory/Ray")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return RayFactory.new(HealingRay):Build()
