--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local Attack = require("@game/ServerScriptService/Server/VFX/Library/Attack")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Reach = require("@game/ReplicatedStorage/Shared/VFX/Library/Reach")
local ShotFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Shot")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- what the server knows of a shot that's out
type Shot = {
	Origin: Vector3,
	Direction: Vector3,
	LaunchTime: number,
}
-- Constants
-- studs from the middle of the avatar a shot may leave from: it starts out at the end of a limb + the two sides never
-- see an avatar in quite the same spot
local ORIGIN_RANGE = 10
-- studs a target may be off the path of a shot: it's hit wherever it sticks out + held to its middle, which the two
-- sides never see in quite the same spot
local PATH_TOLERANCE = 6
-- seconds a shot may be further along than the server makes it: word of where it left from may have been longer on
-- its way than word of what it ran into
local FLIGHT_TOLERANCE = 0.25
-- seconds past the end of its flight a shot is kept for: word of what it ran into last takes a while to get here
local WORD_DELAY = 1
-- the shots of the character that are out, by the id their client gave them
local SHOTS_KEY = "Shots"
-- a cast got as far as letting its shot go, which the client has yet to say where to
local IS_LOADED_KEY = "IsLoaded"
-- Variables
-- References
-- Private Functions
-- whatever can't be in the air any more is dropped on the way
local function getShots(context: ServerContext, lifetime: number): { [number]: Shot }
	local shots = (context.Record[SHOTS_KEY] or {}) :: { [number]: Shot }
	context.Record[SHOTS_KEY] = shots
	local now = os.clock()
	for id, shot in shots do
		if now - shot.LaunchTime > lifetime + WORD_DELAY then
			shots[id] = nil
		end
	end
	return shots
end

-- how far a spot is off the stretch of its path a shot has behind it
local function getPathDistance(shot: Shot, position: Vector3, length: number): number
	local along = math.clamp((position - shot.Origin):Dot(shot.Direction), 0, length)
	return (shot.Origin + shot.Direction * along - position).Magnitude
end
-- Class
local Module = {}

-- the server half of a shot ability: a cast costs energy, everybody else gets to see the shot + a hit the client
-- claims only lands if the server finds the target on the way that shot can have come by then
Module.new = function(ability: ShotFactory.Ability): AbilityBuilder.ServerBuilder
	local layout = ability.Layout
	local bindings = layout.Bindings
	local shared = ability.Config
	local powerRes = PowerDefinition.get(layout.Id)
	assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
	local power = powerRes.Value
	-- as many as a client that's on time can have out at once + one to spare, a made up launch doesn't add to them
	local maxShotCount = math.ceil((shared.Lifetime + WORD_DELAY) / shared.Duration) + 1
	local builder = AbilityBuilder.newServer(layout)

	builder:Guard(bindings.Cast, function(context: ServerContext): boolean
		return context.VFX.fire(SpendEnergy, { Amount = power.EnergyCost })
	end)
	builder:On(bindings.Release, function(context: ServerContext)
		context.Record[IS_LOADED_KEY] = true
	end)

	-- a cast lets one shot fly, from where the server has its avatar
	builder:Guard(bindings.Launch, function(context: ServerContext): boolean
		local launch = context.read(bindings.Launch)
		if not launch or not context.Record[IS_LOADED_KEY] then
			return false
		end
		local count = 0
		for _ in getShots(context, shared.Lifetime) do
			count += 1
		end
		return count < maxShotCount and context.VFX.fire(Reach, { Position = launch.Origin, Range = ORIGIN_RANGE })
	end)
	builder:On(bindings.Launch, function(context: ServerContext)
		local launch = context.read(bindings.Launch)
		if launch then
			context.Record[IS_LOADED_KEY] = nil
			getShots(context, shared.Lifetime)[launch.Id] = {
				Origin = launch.Origin,
				Direction = launch.Direction.Unit,
				LaunchTime = os.clock(),
			}
		end
	end)
	-- the player's own machine shows them their shot right away, this is for everybody else. whoever it can get to
	-- has to see it coming
	builder:FireClient(bindings.Launch, ClientVFXDefinition.Bolt, function(context: ServerContext): ClientVFXType.Bolt
		return ShotFactory.getBolt(shared, context.read(bindings.Launch) :: ShotFactory.Launch, context.Color)
	end, { Audience = "Others", Range = shared.Speed * shared.Lifetime })

	builder:Guard(bindings.Hit, function(context: ServerContext): boolean
		local hit = context.read(bindings.Hit)
		local shot = if hit then getShots(context, shared.Lifetime)[hit.ShotId] else nil
		if not hit or not shot then
			return false
		end
		local target = hit.Target
		if target == context.Character or not target:FindFirstChildWhichIsA("Humanoid") then
			return false
		end
		local age = math.min(os.clock() - shot.LaunchTime + FLIGHT_TOLERANCE, shared.Lifetime)
		return getPathDistance(shot, target:GetPivot().Position, shared.Speed * age) <= PATH_TOLERANCE
	end)
	-- a shot is spent on whoever it ran into first
	builder:On(bindings.Hit, function(context: ServerContext)
		local hit = context.read(bindings.Hit)
		if hit then
			getShots(context, shared.Lifetime)[hit.ShotId] = nil
			context.VFX.fire(Attack, { Target = hit.Target, Amount = power.Damage })
		end
	end)

	return builder
end

return Module
