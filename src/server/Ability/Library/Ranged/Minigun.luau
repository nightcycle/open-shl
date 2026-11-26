--!strict
-- Services
-- Packages
-- Modules
local Minigun = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/Minigun")
local RayFactory = require("@game/ServerScriptService/Server/Ability/Factory/Ray")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return RayFactory.new(Minigun):Build()
