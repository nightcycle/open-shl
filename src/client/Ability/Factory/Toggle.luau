--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local ToggleFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Toggle")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ClientContext = AbilityType.ClientContext
-- Constants
-- what an ability keeps of when it was last turned off
local FINISH_TIME_KEY = "FinishTime"
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the client half of a toggled ability: all there is to it for every one of them is not to start on what the server
-- is sure to turn down, what it looks like while it's on is each ability's own to add
Module.new = function(ability: ToggleFactory.Ability): AbilityBuilder.ClientBuilder
	local layout = ability.Layout
	local bindings = layout.Bindings
	local powerRes = PowerDefinition.get(layout.Id)
	assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
	local energyCost = powerRes.Value.EnergyCost
	local builder = AbilityBuilder.newClient(layout)
	-- one that has to wait before it's turned on again isn't started on early, the server would only turn it down
	local cooldown = ability.Config.Cooldown
	if cooldown then
		builder = builder
			:On(bindings.Finish, function(context: ClientContext)
				context.Record[FINISH_TIME_KEY] = os.clock()
			end)
			:Guard(bindings.Cast, function(context: ClientContext): boolean
				local finishTime = context.Record[FINISH_TIME_KEY] :: number?
				return finishTime == nil or os.clock() - finishTime >= cooldown
			end)
	end
	-- one that's locked on isn't turned off by a click
	if ability.Config.IsLocked then
		builder = builder:Guard(bindings.Cancel, function(): boolean
			return false
		end)
	end
	return builder:Guard(bindings.Cast, function(context: ClientContext): boolean
		local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
		if ModeDefinition.getIfEnergyEnabled() and energy < energyCost then
			context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
			return false
		end
		return true
	end)
end

return Module
