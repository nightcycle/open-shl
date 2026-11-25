--!strict
-- Services
-- Packages
-- Modules
local Cheeseburger = require("@game/ReplicatedStorage/Shared/Prop/Library/Cheeseburger")
local ConsumableFactory = require("@game/ServerScriptService/Server/Prop/Factory/Consumable")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ConsumableFactory.new(Cheeseburger):Build()
