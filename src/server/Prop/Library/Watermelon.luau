--!strict
-- Services
-- Packages
-- Modules
local ConsumableFactory = require("@game/ServerScriptService/Server/Prop/Factory/Consumable")
local Watermelon = require("@game/ReplicatedStorage/Shared/Prop/Library/Watermelon")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ConsumableFactory.new(Watermelon):Build()
