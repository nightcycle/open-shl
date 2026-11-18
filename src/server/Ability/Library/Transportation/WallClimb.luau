--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local DrainEnergy = require("@game/ServerScriptService/Server/VFX/Library/DrainEnergy")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Probe = require("@game/ReplicatedStorage/Shared/VFX/Library/Probe")
local WallClimb = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/WallClimb")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ServerContext = AbilityType.ServerContext
-- Constants
-- seconds between two takes of energy off whoever climbs
local DRAIN_INTERVAL = 1
-- studs the wall may be further off than the client has to find it within: the two sides never see an avatar in
-- quite the same spot
local CLING_TOLERANCE = 2
-- Variables
-- References
-- Private Functions
-- Class
local layout = WallClimb.Layout
local bindings = layout.Bindings
local config = WallClimb.Config
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
-- the server half of the wall climb: climbing costs energy. the avatar is moved by the client of its player, where
-- it is + how it holds itself gets to the others by itself
return AbilityBuilder
	.newServer(layout)
	-- that the avatar is on a wall is the client's word, the server has to find one ahead of it as well. letting go
	-- of it again isn't held against anything: it only ever ends what the client pays for
	:Guard(
		bindings.Cling,
		function(context: ServerContext): boolean
			local distance = context.VFX.fire(Probe, { Range = config.ProbeRange })
			return distance ~= nil and distance < config.ClingDistance + CLING_TOLERANCE
		end
	)
	-- the first take is as the avatar leaves the ground, so there's no energy to turn a climb down over: one without
	-- it is over the moment it began + the client hears of it like of any other end
	:Run(
		bindings.Climb,
		DrainEnergy,
		function(context: ServerContext): DrainEnergy.Properties
			return {
				Amount = energyCost,
				Interval = DRAIN_INTERVAL,
				OnEmpty = function()
					context.raise(bindings.Exhaust, nil)
				end,
			}
		end
	)
	:Build()
