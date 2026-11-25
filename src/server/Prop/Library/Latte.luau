--!strict
-- Services
-- Packages
-- Modules
local ConsumableFactory = require("@game/ServerScriptService/Server/Prop/Factory/Consumable")
local Latte = require("@game/ReplicatedStorage/Shared/Prop/Library/Latte")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ConsumableFactory.new(Latte):Build()
