--!strict
-- Services
local Players = game:GetService("Players")
-- Packages
-- Modules
-- Hooks
local usePlayerCharacter = require("@game/StarterPlayer/StarterPlayerScripts/Client/React/Hook/usePlayerCharacter")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return function(): Model?
	return usePlayerCharacter(Players.LocalPlayer)
end
