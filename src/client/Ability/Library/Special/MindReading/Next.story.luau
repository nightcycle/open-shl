--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
-- Modules
local Ability = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/MindReading")
local AbilityStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Story")
local Client = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Special/MindReading")
local Server = require("@game/ServerScriptService/Server/Ability/Library/Special/MindReading")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- only a game that moves on with a click has it
local binding = Ability.Layout.Bindings.Next
assert(binding, "a click moves on to nobody in this game")
return AbilityStory.new(Client, Server, binding)
