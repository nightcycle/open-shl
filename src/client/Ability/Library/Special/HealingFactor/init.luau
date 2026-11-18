--!strict
-- Services
-- Packages
-- Modules
local HealingFactor = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/HealingFactor")
local ToggleFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Toggle")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- health is the server's to give + there's nothing to see or hear of it but the bar of the hud
return ToggleFactory.new(HealingFactor):Build()
