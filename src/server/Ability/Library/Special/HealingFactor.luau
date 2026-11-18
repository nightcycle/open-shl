--!strict
-- Services
-- Packages
-- Modules
local HealingFactor = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/HealingFactor")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Regenerate = require("@game/ServerScriptService/Server/VFX/Library/Regenerate")
local ToggleFactory = require("@game/ServerScriptService/Server/Ability/Factory/Toggle")
-- Types
-- Constants
-- seconds between two lots of health
local INTERVAL = 2
-- how much health a point of energy buys
local HEALTH_PER_ENERGY = 0.5
-- Variables
-- References
-- Private Functions
-- Class
local layout = HealingFactor.Layout
local bindings = layout.Bindings
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
-- the cast pays for the health that comes right away, whatever comes after it is paid for as it comes
return ToggleFactory.new(HealingFactor)
	:Run(bindings.Sustain, Regenerate, function(): Regenerate.Properties
		return {
			Amount = energyCost * HEALTH_PER_ENERGY,
			Cost = energyCost,
			Interval = INTERVAL,
		}
	end)
	:Build()
