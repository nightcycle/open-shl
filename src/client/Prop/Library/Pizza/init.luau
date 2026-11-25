--!strict
-- Services
-- Packages
-- Modules
local ConsumableFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Factory/Consumable")
local Pizza = require("@game/ReplicatedStorage/Shared/Prop/Library/Pizza")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ConsumableFactory.new(Pizza):Build()
