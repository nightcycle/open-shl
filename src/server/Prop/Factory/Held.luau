--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local HeldFactory = require("@game/ReplicatedStorage/Shared/Prop/Factory/Held")
local PropBuilder = require("@game/ReplicatedStorage/Shared/Prop/Builder")
local PropMoment = require("@game/ReplicatedStorage/Shared/Prop/Moment")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the server half of a prop that's only held. the player's own half shows them what they hold right away, this is
-- for everybody else: whoever joins while it's out included
Module.new = function(held: HeldFactory.Held): PropBuilder.ServerBuilder
	return PropBuilder.newServer(held.Prop)
		:RunClient(PropMoment.Hold, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
			return held.Look
		end, { Audience = "Others" })
end

return Module
