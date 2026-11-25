--!strict
-- Services
-- Packages
-- Modules
local AcousticGuitar = require("@game/ReplicatedStorage/Shared/Prop/Library/AcousticGuitar")
local HeldFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Factory/Held")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return HeldFactory.new(AcousticGuitar):Build()
