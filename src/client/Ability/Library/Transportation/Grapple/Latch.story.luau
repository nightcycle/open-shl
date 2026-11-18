--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
-- Modules
local Ability = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/Grapple")
local AbilityStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Story")
local Client = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Transportation/Grapple")
local Server = require("@game/ServerScriptService/Server/Ability/Library/Transportation/Grapple")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return AbilityStory.new(Client, Server, Ability.Layout.Bindings.Latch, {
	GetPayload = function(stage: AbilityStory.Stage)
		return { Position = stage.Target:GetPivot().Position }
	end,
})
