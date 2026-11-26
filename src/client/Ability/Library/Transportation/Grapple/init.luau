--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local Grapple = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/Grapple")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Projectile = require("@game/ReplicatedStorage/Shared/VFX/Library/Projectile")
local Reach = require("@game/ReplicatedStorage/Shared/VFX/Library/Reach")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientContext = AbilityType.ClientContext
type Cleanup = VFXType.Cleanup
type SoundKey = VFXAssetDefinition.SoundKey
type AnimationKey = VFXAssetDefinition.AnimationKey
-- Constants
-- what the avatar does as a hook leaves, nothing in a game without
local CAST_ANIMATION = GameDefinition.tune(nil :: AnimationKey?, { shl3 = "GunShooting" :: AnimationKey? })
-- seconds between two looks at how far the avatar has left to go
local REEL_INTERVAL = 1 / 30
-- studs the spot pointed at has to be off the limb for the hook to be headed there
local MIN_AIM_DISTANCE = 0.01
-- where the hook that's out was let fly from
local LAUNCH_KEY = "Launch"
-- where the hook is in
local ANCHOR_KEY = "Anchor"
-- when the last hook was let fly
local FIRE_TIME_KEY = "FireTime"
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
assert(config.Color or colorOpt.IsSome, `"{layout.Id}" has no color to fall back on`)
local defaultColor = (config.Color or colorOpt.Value) :: Color3
-- the rope is worn in what the character wears the power in, a character that wears none leaves it as it comes
local function getColor(context: ClientContext): Color3
	return (if config.IsSecondary then context.SecondaryColor else context.Color) or defaultColor
end
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
		local rope = context.VFX.start(
			ClientVFXDefinition.Rope,
			Grapple.getRope(getColor(context), launch.Origin + launch.Direction * config.Range, launch.Origin)
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
	:Run(bindings.Tether, ClientVFXDefinition.Rope, function(context: ClientContext): ClientVFXType.Rope
		return Grapple.getRope(getColor(context), getAnchor(context))
	end)
	:Run(bindings.Reel, ClientVFXDefinition.Reel, function(context: ClientContext): ClientVFXType.Reel
		return { Position = getAnchor(context), Speed = config.ReelSpeed }
	end)
	:While(bindings.Reel, function(context: ClientContext)
		local anchor = getAnchor(context)
		return newCleanup(task.spawn(function()
			while true do
				local distance = (context.Character:GetPivot().Position - anchor).Magnitude
				if distance > config.Range then
					context.raise(bindings.Release, nil)
					return
				elseif distance < config.ArrivalDistance then
					task.wait(config.ReleaseDelay)
					context.raise(bindings.Release, nil)
					return
				end
				task.wait(REEL_INTERVAL)
			end
		end))
	end)

-- not every game has the avatar let a hook go with a move of its own
if CAST_ANIMATION then
	builder = builder:Fire(bindings.Launch, ClientVFXDefinition.AnimationOnce, function(): ClientVFXType.AnimationOnce
		return { Animation = CAST_ANIMATION :: AnimationKey }
	end)
end
-- nor a hook heard at each step of its way
local fireSound = config.FireSound
if fireSound then
	builder = builder:Fire(bindings.Launch, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = fireSound :: SoundKey }
	end)
end
local latchSound = config.LatchSound
if latchSound then
	builder = builder:Fire(bindings.Latch, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = latchSound :: SoundKey }
	end)
end
local tightenSound = config.TightenSound
if tightenSound then
	builder = builder:Fire(bindings.Tighten, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = tightenSound :: SoundKey }
	end)
end
-- a click lets a hook fly the same way whether or not one is in
for _, binding in { bindings.Fire, bindings.Refire } do
	-- one that has to wait before the next hook isn't let fly early, the server would only turn it down
	local cooldown = config.Cooldown
	if cooldown then
		builder = builder
			:Guard(binding, function(context: ClientContext): boolean
				local fireTime = context.Record[FIRE_TIME_KEY] :: number?
				if fireTime == nil or os.clock() - fireTime >= cooldown then
					return true
				end
				if config.IsDroppedEarly and binding == bindings.Refire then
					context.raise(bindings.Release, nil)
				end
				return false
			end)
			:On(binding, function(context: ClientContext)
				context.Record[FIRE_TIME_KEY] = os.clock()
			end)
	end
	builder = builder
		-- the server has the last word on the energy, a hook it's sure to turn down isn't let fly
		:Guard(
			binding,
			function(context: ClientContext): boolean
				local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
				if ModeDefinition.getIfEnergyEnabled() and energy < power.EnergyCost then
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
