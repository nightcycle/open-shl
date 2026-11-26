--!strict
-- Services
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Moneybag = require("@game/ReplicatedStorage/Shared/Prop/Library/Moneybag")
local PropBuilder = require("@game/ReplicatedStorage/Shared/Prop/Builder")
local PropMoment = require("@game/ReplicatedStorage/Shared/Prop/Moment")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type Replication = VFXType.Replication
-- Constants
-- the player's own half shows + plays theirs to them right away, the server tells everybody else
local SEEN: Replication = table.freeze({ Audience = "Others" :: "Others" })
-- studs everybody else hears a throw + sees its bills from: as far as an ability is heard
local THROWN: Replication = table.freeze({ Audience = "Others" :: "Others", Range = 150 })
-- Variables
-- References
-- Private Functions
-- Class
-- the server makes nothing + gives nothing: it tells whoever is near that a handful was thrown
return PropBuilder.newServer(Moneybag.Prop)
	:RunClient(PropMoment.Hold, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
		return Moneybag.Look
	end, SEEN)
	:FireClient(PropMoment.Use, ClientVFXDefinition.Sound, Moneybag.getSound, THROWN)
	:FireClient(PropMoment.Use, ClientVFXDefinition.Scatter, function(): ClientVFXType.Scatter
		return Moneybag.Bills
	end, THROWN)
	:Build()
