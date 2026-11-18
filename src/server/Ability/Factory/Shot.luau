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
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
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
-- seconds of flight to each of the stretches the arc of a shot is checked in
local ARC_INTERVAL = 0.05
-- studs everybody else hears a shot leave from
local SOUND_RANGE = 150
-- seconds ahead of the end of its wind-up a shot may leave: the machine of the server is that far ahead of the clock
-- as well, so a client that's on time isn't turned down over a hiccup of its connection
local RELEASE_TOLERANCE = 0.15
-- the shots of the character that are out, by the id their client gave them
local SHOTS_KEY = "Shots"
-- a cast got as far as letting its shot go, which the client has yet to say where to
local IS_LOADED_KEY = "IsLoaded"
-- when the cast began that has yet to get that far
local CAST_TIME_KEY = "CastTime"
-- word of the shot of that cast is in already, it has none left to let go
local IS_SPENT_KEY = "IsSpent"
-- Variables
-- References
-- Private Functions
-- whether a cast has a shot to let go. one that's wound up by the clock counts before the machine got around to it:
-- word of a shot that takes next to no winding up can get here along with the click it began with
local function getIfLoaded(context: ServerContext, releaseDelay: number): boolean
	local record = context.Record
	if record[IS_LOADED_KEY] then
		return true
	end
	local castTime = record[CAST_TIME_KEY] :: number?
	return castTime ~= nil and not record[IS_SPENT_KEY] and os.clock() - castTime + RELEASE_TOLERANCE >= releaseDelay
end

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

-- how far a spot is off a straight stretch
local function getStretchDistance(origin: Vector3, direction: Vector3, length: number, position: Vector3): number
	local along = math.clamp((position - origin):Dot(direction), 0, length)
	return (origin + direction * along - position).Magnitude
end

-- how far a spot is off the stretch of its path a shot of that age has behind it
local function getPathDistance(shot: Shot, position: Vector3, speed: number, age: number, gravity: number?): number
	if not gravity then
		return getStretchDistance(shot.Origin, shot.Direction, speed * age, position)
	end
	-- the arc of one that's pulled down is gone over in stretches short enough to pass for straight
	local distance = math.huge
	local from = shot.Origin
	for index = 1, math.ceil(age / ARC_INTERVAL) do
		local time = math.min(index * ARC_INTERVAL, age)
		local to = shot.Origin + shot.Direction * speed * time - Vector3.yAxis * gravity * time ^ 2 / 2
		local stretch = to - from
		if stretch.Magnitude > 0 then
			distance = math.min(distance, getStretchDistance(from, stretch.Unit, stretch.Magnitude, position))
		end
		from = to
	end
	return distance
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
	-- a spot off the middle of the limb is that much further out to begin with
	local originRange = ORIGIN_RANGE + (if shared.Offset then shared.Offset.Magnitude else 0)
	local builder = AbilityBuilder
		.newServer(layout)
		:Guard(bindings.Cast, function(context: ServerContext): boolean
			return context.VFX.fire(SpendEnergy, { Amount = power.EnergyCost })
		end)
		:On(bindings.Cast, function(context: ServerContext)
			context.Record[CAST_TIME_KEY] = os.clock()
		end)
		:On(bindings.Release, function(context: ServerContext)
			local record = context.Record
			-- a shot that's out already isn't let go of a second time
			if record[IS_SPENT_KEY] then
				record[IS_SPENT_KEY] = nil
			else
				record[IS_LOADED_KEY] = true
			end
			record[CAST_TIME_KEY] = nil
		end)
		-- a cast lets one shot fly, from where the server has its avatar
		:Guard(
			bindings.Launch,
			function(context: ServerContext): boolean
				local launch = context.read(bindings.Launch)
				if not launch or not getIfLoaded(context, shared.ReleaseDelay) then
					return false
				end
				local count = 0
				for _ in getShots(context, shared.Lifetime) do
					count += 1
				end
				return count < maxShotCount
					and context.VFX.fire(Reach, { Position = launch.Origin, Range = originRange })
			end
		)
		:On(bindings.Launch, function(context: ServerContext)
			local launch = context.read(bindings.Launch)
			if launch then
				local record = context.Record
				if record[IS_LOADED_KEY] then
					record[IS_LOADED_KEY] = nil
				else
					record[IS_SPENT_KEY] = true
				end
				getShots(context, shared.Lifetime)[launch.Id] = {
					Origin = launch.Origin,
					Direction = launch.Direction.Unit,
					LaunchTime = os.clock(),
				}
			end
		end)
		:Guard(bindings.Hit, function(context: ServerContext): boolean
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
			return getPathDistance(shot, target:GetPivot().Position, shared.Speed, age, shared.Gravity)
				<= PATH_TOLERANCE
		end)
		-- a shot is spent on whoever it ran into first
		:On(bindings.Hit, function(context: ServerContext)
			local hit = context.read(bindings.Hit)
			if hit then
				getShots(context, shared.Lifetime)[hit.ShotId] = nil
				context.VFX.fire(Attack, { Target = hit.Target, Amount = power.Damage })
			end
		end)

	-- the player's own machine shows them their shot right away, this is for everybody else. whoever it can get to
	-- has to see it coming, unless there's nothing of it to see
	if not shared.IsHidden then
		builder = builder:FireClient(
			bindings.Launch,
			ClientVFXDefinition.Bolt,
			function(context: ServerContext): ClientVFXType.Bolt
				return ShotFactory.getBolt(shared, context.read(bindings.Launch) :: ShotFactory.Launch, context.Color)
			end,
			{ Audience = "Others", Range = shared.Speed * shared.Lifetime }
		)
	end
	-- not every shot is heard as it leaves
	local launchSound = shared.LaunchSound
	if launchSound then
		builder = builder:FireClient(bindings.Launch, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
			return { Sound = launchSound :: VFXAssetDefinition.SoundKey }
		end, { Audience = "Others", Range = SOUND_RANGE })
	end

	return builder
end

return Module
