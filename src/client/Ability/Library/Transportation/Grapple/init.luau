--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Grapple = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/Grapple")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Projectile = require("@game/ReplicatedStorage/Shared/VFX/Library/Projectile")
local Reach = require("@game/ReplicatedStorage/Shared/VFX/Library/Reach")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientContext = AbilityType.ClientContext
type Cleanup = VFXType.Cleanup
-- Constants
-- studs a second the avatar is pulled to the hook at
local REEL_SPEED = 75
-- seconds between two looks at how far the avatar has left to go
local REEL_INTERVAL = 1 / 30
-- studs from the hook the avatar has arrived within
local ARRIVAL_DISTANCE = 3.5
-- seconds the rope goes on pulling for once the avatar has arrived, which is what gets it all the way there
local RELEASE_DELAY = 0.2
-- studs the spot pointed at has to be off the limb for the hook to be headed there
local MIN_AIM_DISTANCE = 0.01
-- where the hook that's out was let fly from
local LAUNCH_KEY = "Launch"
-- where the hook is in
local ANCHOR_KEY = "Anchor"
-- Variables
-- References
-- Private Functions
-- from the limb that holds the rope to where the player points
local function getLaunch(context: ClientContext): Grapple.Launch?
	local limb = context.Character:FindFirstChild(Grapple.Config.Limb)
	if not limb or not limb:IsA("BasePart") then
		return nil
	end
	local offset = (context.Aim or context.getAim()).Position - limb.Position
	return {
		Origin = limb.Position,
		-- pointed right at the limb there's no telling where to, the hook goes where the avatar looks
		Direction = if offset.Magnitude > MIN_AIM_DISTANCE
			then offset.Unit
			else context.Character:GetPivot().LookVector,
	}
end

-- a machine that was put into a state rather than got there has no hook out, it goes by where its player points
local function getAnchor(context: ClientContext): Vector3
	return (context.Record[ANCHOR_KEY] or context.getAim().Position) :: Vector3
end

-- a loop that's still waiting is cut short. one that ended itself, or is the one asking, is left alone
local function newCleanup(thread: thread): Cleanup
	return function()
		if coroutine.status(thread) == "suspended" then
			task.cancel(thread)
		end
	end
end
-- Class
local layout = Grapple.Layout
local bindings = layout.Bindings
local config = Grapple.Config
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local power = powerRes.Value
local colorOpt = PowerDefinition.getColor(power, nil)
assert(colorOpt.IsSome, `"{layout.Id}" has no color to fall back on`)
local defaultColor = colorOpt.Value
-- the client half of the grapple: the player sees their own hook fly the moment they click, their machine is the one
-- to notice what it runs into + the avatar is theirs to move, so what pulls it along is all here
local builder: AbilityBuilder.ClientBuilder = AbilityBuilder.newClient(layout)
	:Run(bindings.Hold, ClientVFXDefinition.Animation, function(): ClientVFXType.Animation
		return { Animation = "GunHolding" }
	end)
	:On(bindings.Launch, function(context: ClientContext)
		context.Record[LAUNCH_KEY] = context.read(bindings.Launch)
	end)
	:While(bindings.Flight, function(context: ClientContext)
		local launch = (context.Record[LAUNCH_KEY] or getLaunch(context)) :: Grapple.Launch?
		if not launch then
			return function() end
		end
		local color = context.Color or defaultColor
		local rope = context.VFX.start(
			ClientVFXDefinition.Rope,
			Grapple.getRope(color, launch.Origin + launch.Direction * config.Range, launch.Origin)
		)
		local hook = context.VFX.start(Projectile, {
			Origin = launch.Origin,
			Direction = launch.Direction,
			Speed = config.Speed,
			Lifetime = config.Range / config.Speed,
			IsPassingCharacters = true,
			OnHit = function(result: RaycastResult)
				-- a hook that's too far from the avatar to hold is as good as one that ran into nothing
				if context.VFX.fire(Reach, { Position = result.Position, Range = config.Range }) then
					context.raise(bindings.Latch, { Position = result.Position })
				else
					rope.Stop()
				end
			end,
			OnExpired = function()
				rope.Stop()
			end,
		})
		return function()
			hook.Stop()
			rope.Stop()
		end
	end)
	:On(bindings.Latch, function(context: ClientContext)
		local latch = context.read(bindings.Latch)
		if latch then
			context.Record[ANCHOR_KEY] = latch.Position
		end
	end)
	:Fire(bindings.Latch, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = config.LatchSound }
	end)
	:Run(bindings.Tether, ClientVFXDefinition.Rope, function(context: ClientContext): ClientVFXType.Rope
		return Grapple.getRope(context.Color or defaultColor, getAnchor(context))
	end)
	:Run(bindings.Reel, ClientVFXDefinition.Reel, function(context: ClientContext): ClientVFXType.Reel
		return { Position = getAnchor(context), Speed = REEL_SPEED }
	end)
	:While(bindings.Reel, function(context: ClientContext)
		local anchor = getAnchor(context)
		return newCleanup(task.spawn(function()
			while true do
				local distance = (context.Character:GetPivot().Position - anchor).Magnitude
				if distance > config.Range then
					context.raise(bindings.Release, nil)
					return
				elseif distance < ARRIVAL_DISTANCE then
					task.wait(RELEASE_DELAY)
					context.raise(bindings.Release, nil)
					return
				end
				task.wait(REEL_INTERVAL)
			end
		end))
	end)

-- a click lets a hook fly the same way whether or not one is in
for _, binding in { bindings.Fire, bindings.Refire } do
	builder = builder
		-- the server has the last word on the energy, a hook it's sure to turn down isn't let fly
		:Guard(
			binding,
			function(context: ClientContext): boolean
				local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
				if BUILD_CONFIG.ENERGY_ENABLED and energy < power.EnergyCost then
					context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
					return false
				end
				return true
			end
		)
		:On(binding, function(context: ClientContext)
			local launch = getLaunch(context)
			if launch then
				context.raise(bindings.Launch, launch)
			end
		end)
end

return builder:Build()
