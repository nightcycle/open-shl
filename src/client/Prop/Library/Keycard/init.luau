--!strict
-- Services
-- Packages
-- Modules
local HeldFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Factory/Held")
local Keycard = require("@game/ReplicatedStorage/Shared/Prop/Library/Keycard")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return HeldFactory.new(Keycard):Build()
