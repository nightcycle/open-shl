--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
local SuperSpeed = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/SuperSpeed")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerContext = AbilityType.ServerContext
type Cleanup = VFXType.Cleanup
-- Constants
-- seconds between two takes of energy off whoever runs + between two looks at whether there's enough to run on again
local DRAIN_INTERVAL = 0.25
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
local layout = SuperSpeed.Layout
local bindings = layout.Bindings
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
-- the server half of the super speed: running costs energy + everybody else gets to hear it. the avatar is moved by
-- the client of its player, where it is gets to the others by itself
return AbilityBuilder
	.newServer(layout)
	-- only an avatar that's on the move pays, standing about with the tool out is free. there's nothing to turn the
	-- start down with: whoever can't pay for their first step is out of breath the moment they take it
	:While(
		bindings.Sprint,
		function(context: ServerContext)
			local humanoid = context.Character:FindFirstChildWhichIsA("Humanoid")
			return newCleanup(task.spawn(function()
				while true do
					local isMoving = humanoid ~= nil and humanoid.MoveDirection.Magnitude > 0
					if isMoving and not context.VFX.fire(SpendEnergy, { Amount = energyCost }) then
						context.raise(bindings.Exhaust, nil)
						return
					end
					task.wait(DRAIN_INTERVAL)
				end
			end))
		end
	)
	-- the player's own machine has the wind around them on right away, this is for everybody else
	:RunClient(
		bindings.Sprint,
		ClientVFXDefinition.SoundLoop,
		function(): ClientVFXType.SoundLoop
			return { Sound = SuperSpeed.Config.Sound }
		end,
		{ Audience = "Others" }
	)
	-- whoever ran out is back at full pace as soon as they can pay for a step again
	:While(
		bindings.Rest,
		function(context: ServerContext)
			return newCleanup(task.spawn(function()
				while AttributeDefinition.get(context.Character, AttributeDefinition.Energy) < energyCost do
					task.wait(DRAIN_INTERVAL)
				end
				context.raise(bindings.Recover, nil)
			end))
		end
	)
	:Build()
