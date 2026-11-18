--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Grapple = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/Grapple")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Reach = require("@game/ReplicatedStorage/Shared/VFX/Library/Reach")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- what the server knows of the hook that's out
type Shot = {
	Origin: Vector3,
	Direction: Vector3,
	LaunchTime: number,
}
-- Constants
-- studs everybody else hears a hook go in from
local SOUND_RANGE = 150
-- studs from the middle of the avatar a hook may leave from: it starts out at the end of a limb + the two sides never
-- see an avatar in quite the same spot
local ORIGIN_RANGE = 10
-- studs a hook may be in off the path it was let fly on, a remote doesn't hand a vector on bit for bit
local PATH_TOLERANCE = 1
-- seconds a hook may be further along than the server makes it: word of where it left from may have been longer on
-- its way than word of what it ran into
local FLIGHT_TOLERANCE = 0.25
-- studs a hook may be in further off than it holds at: the two sides never see an avatar in quite the same spot
local RANGE_TOLERANCE = 10
-- the hook of the character that's out
local SHOT_KEY = "Shot"
-- where the hook is in
local ANCHOR_KEY = "Anchor"
-- Variables
-- References
-- Private Functions
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
-- the server half of the grapple: a hook costs energy, everybody else gets to see the rope + a hook the client
-- claims is in only counts where the server finds that it can have got to. the avatar is moved by the client of its
-- player, where it ends up gets to the others by itself
local builder: AbilityBuilder.ServerBuilder = AbilityBuilder
	.newServer(layout)
	-- a click pays for one hook, from where the server has the avatar
	:Guard(
		bindings.Launch,
		function(context: ServerContext): boolean
			local launch = context.read(bindings.Launch)
			return launch ~= nil and context.VFX.fire(Reach, { Position = launch.Origin, Range = ORIGIN_RANGE })
		end
	)
	:On(bindings.Launch, function(context: ServerContext)
		local launch = context.read(bindings.Launch)
		if launch then
			local shot: Shot = {
				Origin = launch.Origin,
				Direction = launch.Direction.Unit,
				LaunchTime = os.clock(),
			}
			context.Record[SHOT_KEY] = shot
		end
	end)
	-- the player's own machine shows them their rope right away, this is for everybody else
	:While(
		bindings.Flight,
		function(context: ServerContext)
			local shot = context.Record[SHOT_KEY] :: Shot?
			if not shot then
				return function() end
			end
			local rope: ClientVFXType.Rope =
				Grapple.getRope(context.Color or defaultColor, shot.Origin + shot.Direction * config.Range, shot.Origin)
			return context.VFX.startClient(ClientVFXDefinition.Rope, rope, nil, { Audience = "Others" }).Stop
		end
	)
	-- a hook is in where the client says if that's on the path it was let fly on, no further along it than it can
	-- have come by now + no further from the avatar than a rope holds
	:Guard(
		bindings.Latch,
		function(context: ServerContext): boolean
			local latch = context.read(bindings.Latch)
			local shot = context.Record[SHOT_KEY] :: Shot?
			if not latch or not shot then
				return false
			end
			local age = os.clock() - shot.LaunchTime + FLIGHT_TOLERANCE
			local along = (latch.Position - shot.Origin):Dot(shot.Direction)
			local pathDistance = (shot.Origin + shot.Direction * along - latch.Position).Magnitude
			return along >= 0
				and along <= config.Speed * age
				and pathDistance <= PATH_TOLERANCE
				and context.VFX.fire(Reach, { Position = latch.Position, Range = config.Range + RANGE_TOLERANCE })
		end
	)
	:On(bindings.Latch, function(context: ServerContext)
		local latch = context.read(bindings.Latch)
		if latch then
			context.Record[ANCHOR_KEY] = latch.Position
		end
	end)
	:FireClient(bindings.Latch, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = config.LatchSound }
	end, { Audience = "Others", Range = SOUND_RANGE })
	:While(bindings.Tether, function(context: ServerContext)
		local anchor = context.Record[ANCHOR_KEY] :: Vector3?
		if not anchor then
			return function() end
		end
		local rope: ClientVFXType.Rope = Grapple.getRope(context.Color or defaultColor, anchor)
		return context.VFX.startClient(ClientVFXDefinition.Rope, rope, nil, { Audience = "Others" }).Stop
	end)

-- a hook costs the same whether or not one is in. letting go of one isn't held against anything: it only ever ends
-- what the client paid for
for _, binding in { bindings.Fire, bindings.Refire } do
	builder = builder:Guard(binding, function(context: ServerContext): boolean
		return context.VFX.fire(SpendEnergy, { Amount = power.EnergyCost })
	end)
end

return builder:Build()
