--!strict
-- Services
-- Packages
-- Modules
local ElectricGuitar = require("@game/ReplicatedStorage/Shared/Prop/Library/ElectricGuitar")
local HeldFactory = require("@game/ServerScriptService/Server/Prop/Factory/Held")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return HeldFactory.new(ElectricGuitar):Build()
