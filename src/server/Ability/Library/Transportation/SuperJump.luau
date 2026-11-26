--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local SuperJump = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/SuperJump")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- how an avatar jumps is its client's own to say + jumping costs nothing: there's nothing for the server to check,
-- spend or show anybody
return AbilityBuilder.newServer(SuperJump.Layout):Build()
