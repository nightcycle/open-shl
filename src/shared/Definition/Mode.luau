--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
-- Constants
-- a place that's built for one mode has what it plays by baked in. a private server is whatever its owner set it up
-- as, which its server only learns as it starts
local IS_SET_BY_SERVER = BUILD_CONFIG.MODE == "private-server"
-- where the owner of a private server has a toggle, if its players fight is the server's to say in every place: the
-- toggle flips that + nothing else, a game without an energy bar isn't handed one by it
local IS_PVP_SET_BY_SERVER = IS_SET_BY_SERVER or GameDefinition.FEATURES.PrivateServerToggle
-- Variables
-- References
-- Private Functions
-- a private server with pvp on plays by everything a combat place does
local function getIfCombat(): boolean
	return AttributeDefinition.get(Workspace, AttributeDefinition.IsPVP) == true
end
-- Class
local Module = {}

Module.IS_PVP_SET_BY_SERVER = IS_PVP_SET_BY_SERVER

Module.getIfPVPEnabled = function(): boolean
	return if IS_PVP_SET_BY_SERVER then getIfCombat() else BUILD_CONFIG.PVP_ENABLED
end

Module.getIfEnergyEnabled = function(): boolean
	return if IS_SET_BY_SERVER then getIfCombat() else BUILD_CONFIG.ENERGY_ENABLED
end

Module.getIfQuestsEnabled = function(): boolean
	return if IS_SET_BY_SERVER then getIfCombat() else BUILD_CONFIG.QUESTS_ENABLED
end

-- yields until the server has said what it plays by, a place built for one mode knows from the start
Module.await = function()
	if not IS_PVP_SET_BY_SERVER then
		return
	end
	local name = AttributeDefinition.IsPVP.Name
	while Workspace:GetAttribute(name) == nil do
		Workspace:GetAttributeChangedSignal(name):Wait()
	end
end

-- told at once + again whenever the server changes its mind, until what's returned is called. whatever goes by whether
-- players fight asks here, so none of it has to know what kind of server it's on. a place that has it baked in tells once
Module.observe = function(fn: (isPVP: boolean) -> ()): () -> ()
	fn(Module.getIfPVPEnabled())
	if not IS_PVP_SET_BY_SERVER then
		return function() end
	end
	local connection = Workspace:GetAttributeChangedSignal(AttributeDefinition.IsPVP.Name):Connect(function()
		fn(Module.getIfPVPEnabled())
	end)
	return function()
		connection:Disconnect()
	end
end

return Module
