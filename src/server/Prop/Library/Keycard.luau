--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Keycard = require("@game/ReplicatedStorage/Shared/Prop/Library/Keycard")
local PropBuilder = require("@game/ReplicatedStorage/Shared/Prop/Builder")
local PropMoment = require("@game/ReplicatedStorage/Shared/Prop/Moment")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the player's own half shows them what they hold right away, this is for everybody else: whoever joins while it's
-- out included
return PropBuilder.newServer(Keycard.Prop)
	:RunClient(PropMoment.Hold, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
		return Keycard.Card
	end, { Audience = "Others" })
	:Build()
