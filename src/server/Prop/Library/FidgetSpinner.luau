--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local FidgetSpinner = require("@game/ReplicatedStorage/Shared/Prop/Library/FidgetSpinner")
local PropBuilder = require("@game/ReplicatedStorage/Shared/Prop/Builder")
local PropMoment = require("@game/ReplicatedStorage/Shared/Prop/Moment")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local PropType = require("@game/ReplicatedStorage/Shared/Type/Prop")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerContext = PropType.ServerContext
type Cleanup = VFXType.Cleanup
type Replication = VFXType.Replication
-- Constants
-- the player's own half shows theirs to them right away, the server tells everybody else
local SEEN: Replication = table.freeze({ Audience = "Others" :: "Others" })
-- Variables
-- References
-- Private Functions
local function getLook(context: ServerContext): ClientVFXType.Prop
	return FidgetSpinner.getLook(context.Memory)
end

-- the flick comes first: what shows the use after it is handed the speed it turns at from here on
local function flick(context: ServerContext): Cleanup
	FidgetSpinner.flick(context.Memory, Workspace:GetServerTimeNow())
	return function() end
end
-- Class
-- everybody else is told of a flick once, as a speed + when: their screens turn it from there, whoever comes by
-- later included
return PropBuilder.newServer(FidgetSpinner.Prop)
	:While(PropMoment.Using, flick)
	:RunClient(PropMoment.Rest, ClientVFXDefinition.Prop, getLook, SEEN)
	:RunClient(PropMoment.Using, ClientVFXDefinition.Prop, getLook, SEEN)
	:Build()
