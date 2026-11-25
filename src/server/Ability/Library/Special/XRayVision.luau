--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local XRayVision = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/XRayVision")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- what a player's own screen shows of what their machine already has is theirs to say: there's nothing for the
-- server to check, spend or show anybody
return AbilityBuilder.newServer(XRayVision.Layout):Build()
