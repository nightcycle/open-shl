--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
-- Modules
local Ability = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/MachineGun")
local AbilityStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Story")
local Client = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/MachineGun")
local Server = require("@game/ServerScriptService/Server/Ability/Library/Ranged/MachineGun")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local binding = Ability.Layout.Bindings.ReloadKey
assert(binding, `"{Ability.Layout.Id}" has no ReloadKey`)

return AbilityStory.new(Client, Server, binding)
