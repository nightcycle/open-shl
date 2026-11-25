--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ConsumableFactory = require("@game/ReplicatedStorage/Shared/Prop/Factory/Consumable")
local Heal = require("@game/ServerScriptService/Server/VFX/Library/Heal")
local PropBuilder = require("@game/ReplicatedStorage/Shared/Prop/Builder")
local PropMoment = require("@game/ReplicatedStorage/Shared/Prop/Moment")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Replication = VFXType.Replication
-- Constants
-- the player's own half shows + plays theirs to them right away, the server tells everybody else
local SEEN: Replication = table.freeze({ Audience = "Others" :: "Others" })
-- studs everybody else hears it from: as far as an ability is heard
local HEARD: Replication = table.freeze({ Audience = "Others" :: "Others", Range = 150 })
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the server half of something to eat or drink. what a use gives is nobody's to claim: it comes at the end of a use
-- the server timed, one that's cut short never gets there
Module.new = function(consumable: ConsumableFactory.Consumable): PropBuilder.ServerBuilder
	local builder = PropBuilder.newServer(consumable.Prop)
		:RunClient(PropMoment.Rest, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
			return consumable.Rest
		end, SEEN)
		:RunClient(PropMoment.Using, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
			return consumable.Use
		end, SEEN)
		:FireClient(PropMoment.Use, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
			return consumable.UseSound
		end, HEARD)
	local drawSound = consumable.DrawSound
	if drawSound then
		builder = builder:FireClient(PropMoment.Draw, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
			return drawSound
		end, HEARD)
	end
	local health = consumable.Health
	if health then
		builder = builder:Fire(PropMoment.Finish, Heal, function(): Heal.Properties
			return { Amount = health }
		end)
	end
	return builder
end

return Module
