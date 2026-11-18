--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Probe = require("@game/ReplicatedStorage/Shared/VFX/Library/Probe")
local WallClimb = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/WallClimb")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientContext = AbilityType.ClientContext
type Cleanup = VFXType.Cleanup
-- Constants
-- seconds between two looks at what's ahead of the avatar
local PROBE_INTERVAL = 0.1
-- studs a second the avatar rises at
local CLIMB_SPEED = 15
-- studs ahead of the middle of the avatar the wall has to be gone from for the climb to be over
local RELEASE_DISTANCE = 2
-- seconds the avatar goes on rising for once the wall is gone, which is what gets its feet over the edge
local RELEASE_DELAY = 0.2
-- Variables
-- References
-- Private Functions
-- a loop that's still waiting is cut short. one that ended itself, or is the one asking, is left alone
local function newCleanup(thread: thread): Cleanup
	return function()
		if coroutine.status(thread) == "suspended" then
			task.cancel(thread)
		end
	end
end
-- Class
local layout = WallClimb.Layout
local bindings = layout.Bindings
local config = WallClimb.Config
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
-- the client half of the wall climb: the avatar is the player's own to move, so finding the wall + what carries it
-- up is all here, everybody else sees where it ends up
return AbilityBuilder.newClient(layout)
	:While(bindings.Seek, function(context: ClientContext)
		return newCleanup(task.spawn(function()
			while true do
				local distance = context.VFX.fire(Probe, { Range = config.ProbeRange })
				if distance and distance < config.ClingDistance then
					local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
					if not BUILD_CONFIG.ENERGY_ENABLED or energy >= energyCost then
						context.raise(bindings.Cling, nil)
						return
					end
					-- the server has the last word on the energy, a climb it's sure to end right away isn't started on
					context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
				end
				task.wait(PROBE_INTERVAL)
			end
		end))
	end)
	:Run(bindings.Climb, ClientVFXDefinition.Lift, function(): ClientVFXType.Lift
		return { Speed = CLIMB_SPEED, Clearance = RELEASE_DISTANCE }
	end)
	:Run(bindings.Climb, ClientVFXDefinition.Animation, function(): ClientVFXType.Animation
		return { Animation = "WallClimbing" }
	end)
	:While(bindings.Climb, function(context: ClientContext)
		return newCleanup(task.spawn(function()
			while true do
				task.wait(PROBE_INTERVAL)
				local distance = context.VFX.fire(Probe, { Range = config.ProbeRange })
				if not distance or distance >= RELEASE_DISTANCE then
					task.wait(RELEASE_DELAY)
					context.raise(bindings.Release, nil)
					return
				end
			end
		end))
	end)
	:Build()
