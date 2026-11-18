--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local MindReading = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/MindReading")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- the world loses its color + its edges for whoever looks in on somebody
local FILTER: ClientVFXType.ScreenFilter = table.freeze({
	Brightness = 0.3,
	Contrast = 0.1,
	Saturation = -1,
	Blur = 7,
})
-- Variables
-- References
-- Private Functions
-- Class
local layout = MindReading.Layout
local bindings = layout.Bindings
-- all of it happens on the screen of the player: nobody else sees or hears a thing, whoever is looked in on included
return AbilityBuilder.newClient(layout)
	:Run(bindings.Read, ClientVFXDefinition.ScreenFilter, function(): ClientVFXType.ScreenFilter
		return FILTER
	end)
	:Run(bindings.Read, ClientVFXDefinition.Spectate, function(): ClientVFXType.Spectate
		return {}
	end)
	:Build()
