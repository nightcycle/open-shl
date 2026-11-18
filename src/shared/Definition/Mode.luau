--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
-- Types
-- Constants
-- a place that's built for one mode has what it plays by baked in. a private server is whatever its owner set it up
-- as, which its server only learns as it starts
local IS_SET_BY_SERVER = BUILD_CONFIG.MODE == "private-server"
-- Variables
-- References
-- Private Functions
-- a private server with pvp on plays by everything a combat place does
local function getIfCombat(): boolean
	return AttributeDefinition.get(Workspace, AttributeDefinition.IsPVP) == true
end
-- Class
local Module = {}

Module.getIfPVPEnabled = function(): boolean
	return if IS_SET_BY_SERVER then getIfCombat() else BUILD_CONFIG.PVP_ENABLED
end

Module.getIfEnergyEnabled = function(): boolean
	return if IS_SET_BY_SERVER then getIfCombat() else BUILD_CONFIG.ENERGY_ENABLED
end

Module.getIfQuestsEnabled = function(): boolean
	return if IS_SET_BY_SERVER then getIfCombat() else BUILD_CONFIG.QUESTS_ENABLED
end

-- yields until the server has said what it plays by, a place built for one mode knows from the start
Module.await = function()
	if not IS_SET_BY_SERVER then
		return
	end
	local name = AttributeDefinition.IsPVP.Name
	while Workspace:GetAttribute(name) == nil do
		Workspace:GetAttributeChangedSignal(name):Wait()
	end
end

return Module
