--!strict
-- Services
-- Packages
-- Modules
local HeldFactory = require("@game/ServerScriptService/Server/Prop/Factory/Held")
local Tablet = require("@game/ReplicatedStorage/Shared/Prop/Library/Tablet")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return HeldFactory.new(Tablet):Build()
