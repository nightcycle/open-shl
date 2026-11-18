--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
-- Modules
local Ability = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/LightningHand")
local AbilityStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Story")
local Client = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/LightningHand")
local Server = require("@game/ServerScriptService/Server/Ability/Library/Ranged/LightningHand")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return AbilityStory.new(Client, Server, Ability.Layout.Bindings.Launch, {
	GetPayload = function(stage: AbilityStory.Stage)
		return {
			Id = 1,
			Origin = stage.User:GetPivot().Position,
			Direction = (stage.Target:GetPivot().Position - stage.User:GetPivot().Position).Unit,
		}
	end,
})
