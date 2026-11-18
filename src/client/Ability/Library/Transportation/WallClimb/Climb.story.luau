--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
-- Modules
local Ability = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/WallClimb")
local AbilityStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Story")
local Client = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Transportation/WallClimb")
local Server = require("@game/ServerScriptService/Server/Ability/Library/Transportation/WallClimb")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the target is the wall: the climb lasts until the user has risen past it, further apart it's over right away
return AbilityStory.new(Client, Server, Ability.Layout.Bindings.Climb, {
	Distance = 2,
})
