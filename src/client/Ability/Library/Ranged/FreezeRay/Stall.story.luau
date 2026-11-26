--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
-- Modules
local Ability = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/FreezeRay")
local AbilityStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Story")
local Client = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/FreezeRay")
local Server = require("@game/ServerScriptService/Server/Ability/Library/Ranged/FreezeRay")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local binding = Ability.Layout.Bindings.Stall
assert(binding, "nothing holds the freeze ray up")
return AbilityStory.new(Client, Server, binding)
