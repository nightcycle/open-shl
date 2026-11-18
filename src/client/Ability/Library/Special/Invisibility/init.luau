--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Invisibility = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/Invisibility")
local ToggleFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Toggle")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local bindings = Invisibility.Layout.Bindings
-- the player is gone from their own screen as well, the moment they click
return ToggleFactory.new(Invisibility)
	:Fire(bindings.Cast, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Invisibility.CastSound }
	end)
	:Run(bindings.Sustain, ClientVFXDefinition.Cloak, function(): ClientVFXType.Cloak
		return Invisibility.Cloak
	end)
	:Fire(bindings.Finish, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Invisibility.FinishSound }
	end)
	:Build()
