--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local Camouflage = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/Camouflage")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Flag = require("@game/ServerScriptService/Server/VFX/Library/Flag")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- Constants
-- studs everybody else hears the avatar change + change back from
local SOUND_RANGE = 150
-- Variables
-- References
-- Private Functions
-- Class
local layout = Camouflage.Layout
local bindings = layout.Bindings
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
-- the server half of the camouflage: a cast costs energy + everybody else gets to see the avatar in the look its
-- player found. that look is the client's word: it's only ever a material + a color, so there's nothing to hold it
-- against, + it only counts once for every cast that was paid for
return AbilityBuilder
	.newServer(layout)
	-- only a cast has a price. taking a look off isn't held against anything: it only ever ends what the client
	-- paid for
	:Guard(
		bindings.Cast,
		function(context: ServerContext): boolean
			return context.VFX.fire(SpendEnergy, { Amount = energyCost })
		end
	)
	:On(bindings.Blend, function(context: ServerContext)
		context.Record[Camouflage.SurfaceKey] = context.read(bindings.Blend)
	end)
	-- the player's own machine shows + plays all of it right away, this is for everybody else, whoever joins while
	-- the look is on included
	:RunClient(
		bindings.Disguise,
		ClientVFXDefinition.Coat,
		function(context: ServerContext): ClientVFXType.Coat
			return context.Record[Camouflage.SurfaceKey] :: Camouflage.Surface
		end,
		{ Audience = "Others" }
	)
	-- a name over its head would give the avatar away
	:Run(bindings.Disguise, Flag, function(): Flag.Properties
		return { Attribute = AttributeDefinition.IsNameHidden }
	end)
	:FireClient(bindings.Cast, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Camouflage.CastSound }
	end, { Audience = "Others", Range = SOUND_RANGE })
	:FireClient(bindings.Shed, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Camouflage.ResetSound }
	end, { Audience = "Others", Range = SOUND_RANGE })
	:FireClient(bindings.Fade, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Camouflage.ResetSound }
	end, { Audience = "Others", Range = SOUND_RANGE })
	:Build()
