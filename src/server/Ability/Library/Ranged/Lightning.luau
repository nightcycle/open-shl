--!strict
-- Services
-- Packages
-- Modules
local Lightning = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/Lightning")
local RayFactory = require("@game/ServerScriptService/Server/Ability/Factory/Ray")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return RayFactory.new(Lightning):Build()
