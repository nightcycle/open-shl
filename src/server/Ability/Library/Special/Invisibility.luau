--!strict
-- Services
-- Packages
-- Modules
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Flag = require("@game/ServerScriptService/Server/VFX/Library/Flag")
local Invisibility = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/Invisibility")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
local ToggleFactory = require("@game/ServerScriptService/Server/Ability/Factory/Toggle")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- Constants
-- studs everybody else hears the avatar go + come back from
local SOUND_RANGE = 150
-- Variables
-- References
-- Private Functions
-- Class
local layout = Invisibility.Layout
local bindings = layout.Bindings
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
-- the player's own machine takes their avatar off their screen right away, this is for everybody else: they stop
-- seeing it + the name over its head, whoever joins while it's gone included
return ToggleFactory
	.new(Invisibility)
	:FireClient(bindings.Cast, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Invisibility.CastSound }
	end, { Audience = "Others", Range = SOUND_RANGE })
	:RunClient(bindings.Sustain, ClientVFXDefinition.Cloak, function(): ClientVFXType.Cloak
		return Invisibility.Cloak
	end, { Audience = "Others" })
	:Run(bindings.Sustain, Flag, function(): Flag.Properties
		return { Attribute = AttributeDefinition.IsNameHidden }
	end)
	-- coming back with a click takes the price of a cast once more off whoever has it, it's free for whoever doesn't
	:On(
		bindings.Cancel,
		function(context: ServerContext)
			context.VFX.fire(SpendEnergy, { Amount = energyCost, IsQuiet = true })
		end
	)
	:FireClient(bindings.Finish, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Invisibility.FinishSound }
	end, { Audience = "Others", Range = SOUND_RANGE })
	:Build()
