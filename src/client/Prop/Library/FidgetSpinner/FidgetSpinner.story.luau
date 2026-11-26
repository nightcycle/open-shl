--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
-- Modules
local Client = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Library/FidgetSpinner")
local PropStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Prop/Story")
local Server = require("@game/ServerScriptService/Server/Prop/Library/FidgetSpinner")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return PropStory.new(Client, Server)
