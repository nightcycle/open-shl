--!strict
-- Services
-- Packages
-- Modules
local MachineGun = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/MachineGun")
local RayFactory = require("@game/ServerScriptService/Server/Ability/Factory/Ray")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return RayFactory.new(MachineGun):Build()
