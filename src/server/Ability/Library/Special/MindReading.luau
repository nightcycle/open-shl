--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local MindReading = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/MindReading")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- where a player's own camera looks is theirs to say + looking costs nothing: there's nothing for the server to
-- check, spend or show anybody
return AbilityBuilder.newServer(MindReading.Layout):Build()
