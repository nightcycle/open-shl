--!strict
-- Services
-- Packages
-- Modules
local HeldFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Factory/Held")
local PizzaBox = require("@game/ReplicatedStorage/Shared/Prop/Library/PizzaBox")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return HeldFactory.new(PizzaBox):Build()
