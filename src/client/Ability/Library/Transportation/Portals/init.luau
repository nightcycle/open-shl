--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local PlayAreaDefinition = require("@game/ReplicatedStorage/Shared/Definition/PlayArea")
local Portals = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/Portals")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ClientContext = AbilityType.ClientContext
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
local layout = Portals.Layout
local bindings = layout.Bindings
local config = Portals.Config
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
local hasShot = config.Shot ~= nil
-- the cast is heard as the portal opens, or as the shot that carries it leaves
local heardAt = if hasShot then bindings.Cast else bindings.Open
-- the client half of the portals: they're the server's to make + to watch, the avatar is the player's own to move
-- once it's told that it walked into one
return AbilityBuilder
	.newClient(layout)
	-- the server has the last word on the energy, a cast it's sure to turn down isn't started on
	:Guard(
		bindings.Cast,
		function(context: ClientContext): boolean
			local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
			if ModeDefinition.getIfEnergyEnabled() and energy < energyCost then
				context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
				return false
			end
			return true
		end
	)
	-- no portal opens off the map. a shot finds its own spot, the click it's let fly by may point anywhere
	:Guard(
		bindings.Cast,
		function(context: ClientContext): boolean
			return hasShot or PlayAreaDefinition.getIfInside((context.Aim or context.getAim()).Position)
		end
	)
	:Fire(bindings.Cast, ClientVFXDefinition.AnimationOnce, function(): ClientVFXType.AnimationOnce
		return { Animation = "PowerShot" }
	end)
	-- the portal itself is the server's to make, what it sounds like doesn't have to wait for it
	:Fire(
		heardAt,
		ClientVFXDefinition.Sound,
		function(): ClientVFXType.Sound
			return { Sound = config.OpenSound }
		end
	)
	:Fire(bindings.Travel, ClientVFXDefinition.Warp, function(context: ClientContext): ClientVFXType.Warp
		local travel = context.read(bindings.Travel) :: Portals.Travel
		return { Position = travel.Position }
	end)
	:Fire(bindings.Travel, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = config.TravelSound }
	end)
	:Build()
