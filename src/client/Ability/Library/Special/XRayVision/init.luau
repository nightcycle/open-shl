--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local XRayVision = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/XRayVision")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- the world goes pale + blue for whoever looks through it
local FILTER: ClientVFXType.ScreenFilter = table.freeze({
	Brightness = 1,
	Contrast = 2,
	Saturation = 0,
	Blur = 0,
	TintColor = Color3.fromRGB(68, 117, 170),
})
-- what's within 80 studs of the camera is seen through: three looks a turn through a grid of 20 by 20. the legacy
-- power looked a single stud deep from 80 studs out, which caught next to nothing
local SEE_THROUGH: ClientVFXType.SeeThrough = table.freeze({
	Range = 80,
	Transparency = 0.7,
	RayCount = 400,
	PassCount = 3,
})
-- Variables
-- References
-- Private Functions
-- Class
local layout = XRayVision.Layout
local bindings = layout.Bindings
-- all of it happens on the screen of the player: nobody else sees a thing + nobody is shown any other than they are
return AbilityBuilder.newClient(layout)
	:Run(bindings.See, ClientVFXDefinition.ScreenFilter, function(): ClientVFXType.ScreenFilter
		return FILTER
	end)
	:Run(bindings.See, ClientVFXDefinition.SeeThrough, function(): ClientVFXType.SeeThrough
		return SEE_THROUGH
	end)
	:Build()
