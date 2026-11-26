--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
-- Modules
local Ability = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/Lightning")
local AbilityStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Story")
local Client = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/Lightning")
local Server = require("@game/ServerScriptService/Server/Ability/Library/Ranged/Lightning")
-- Components
-- Hooks
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the ray the user lets go at the target from their right hand, as their client would word it
return AbilityStory.new(Client, Server, Ability.Layout.Bindings.Fire, {
	GetPayload = function(stage: AbilityStory.Stage)
		local hand = stage.User:FindFirstChild("RightHand")
		local origin = if hand and hand:IsA("BasePart") then hand.Position else stage.User:GetPivot().Position
		local offset = stage.Target:GetPivot().Position - origin
		return {
			Id = 1,
			Origin = origin,
			Direction = offset.Unit,
			Distance = math.min(offset.Magnitude, Ability.Config.Range),
			Target = stage.Target,
		}
	end,
})
