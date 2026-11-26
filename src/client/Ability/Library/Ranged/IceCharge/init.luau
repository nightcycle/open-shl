--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local IceCharge = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/IceCharge")
local ShotFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Shot")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
local BINDINGS = IceCharge.Layout.Bindings
-- Variables
-- References
-- Private Functions
-- Class
-- a shot like any other but for the hand filling while the button is down: the throw is played as the ball leaves
return ShotFactory.new(IceCharge.Shot, {
	CastAnimation = "PowerShot",
})
	:Run(BINDINGS.Charging, ClientVFXDefinition.Flame, function(): ClientVFXType.Flame
		return IceCharge.FLAME
	end)
	:Run(BINDINGS.Charging, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
		return IceCharge.BALL
	end)
	:Build()
