--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local Attack = require("@game/ServerScriptService/Server/VFX/Library/Attack")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Kunai = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/Kunai")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Reach = require("@game/ReplicatedStorage/Shared/VFX/Library/Reach")
local ServerShot = require("@game/ServerScriptService/Server/Ability/Factory/Shot")
local ShotFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Shot")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ServerContext = AbilityType.ServerContext
type Handle = VFXType.Handle
-- Constants
local BINDINGS = Kunai.Layout.Bindings
local SHOT = Kunai.Config
-- studs everybody else hears the hand from
local SOUND_RANGE = 150
-- how many the hand holds
local COUNT_KEY = "Count"
-- when the first of them got there
local LOAD_TIME_KEY = "LoadTime"
-- how many of a throw its client has yet to say where to
local LEFT_KEY = "Left"
-- what everybody else is shown in the hand
local PROPS_KEY = "Props"
-- Variables
-- References
-- Private Functions
local function getCount(context: ServerContext): number
	return (context.Record[COUNT_KEY] or 0) :: number
end

-- one more in the hand for everybody else, their own player has it there already
local function addProp(context: ServerContext)
	local handles = context.Record[PROPS_KEY] :: { Handle }?
	if handles then
		table.insert(
			handles,
			context.VFX.startClient(ClientVFXDefinition.Prop, Kunai.getProp(#handles + 1), nil, { Audience = "Others" })
		)
	end
end
-- Class
local powerRes = PowerDefinition.get(Kunai.Layout.Id)
assert(powerRes.IsOk, `no power is registered as "{Kunai.Layout.Id}"`)
local power = powerRes.Value

-- the server half of the kunai: it counts what its client takes in the hand for itself, lets a throw be as many shots
-- as that + holds each of them to its own path, the way any shot is held
return AbilityBuilder
	.newServer(Kunai.Layout)
	:Guard(BINDINGS.Ready, function(context: ServerContext): boolean
		return context.VFX.fire(SpendEnergy, { Amount = power.EnergyCost })
	end)
	:On(BINDINGS.Ready, function(context: ServerContext)
		context.Record[COUNT_KEY] = 1
		context.Record[LOAD_TIME_KEY] = os.clock()
	end)
	-- one more only counts for as long as a client that's on time can have asked for it
	:Guard(
		BINDINGS.Add,
		function(context: ServerContext): boolean
			local loadTime = (context.Record[LOAD_TIME_KEY] or 0) :: number
			return Kunai.getIfAdding(getCount(context), os.clock() - loadTime - ServerShot.RELEASE_TOLERANCE)
		end
	)
	:On(BINDINGS.Add, function(context: ServerContext)
		context.Record[COUNT_KEY] = getCount(context) + 1
		addProp(context)
	end)
	:While(BINDINGS.Load, function(context: ServerContext): VFXType.Cleanup
		local handles: { Handle } = {}
		context.Record[PROPS_KEY] = handles
		addProp(context)
		return function()
			context.Record[PROPS_KEY] = nil
			for _, handle in handles do
				handle.Stop()
			end
		end
	end)
	:On(BINDINGS.Throw, function(context: ServerContext)
		context.Record[LEFT_KEY] = getCount(context)
		context.Record[COUNT_KEY] = 0
	end)
	:On(BINDINGS.Sheathe, function(context: ServerContext)
		context.Record[COUNT_KEY] = 0
	end)
	-- a throw is as many shots as the hand held, each from where the server has its avatar
	:Guard(
		BINDINGS.Launch,
		function(context: ServerContext): boolean
			local launch = context.read(BINDINGS.Launch)
			local left = (context.Record[LEFT_KEY] or 0) :: number
			return launch ~= nil
				and left > 0
				and ServerShot.getShots(context, SHOT.Lifetime)[launch.Id] == nil
				and context.VFX.fire(Reach, { Position = launch.Origin, Range = ServerShot.ORIGIN_RANGE })
		end
	)
	:On(BINDINGS.Launch, function(context: ServerContext)
		local launch = context.read(BINDINGS.Launch)
		if launch then
			context.Record[LEFT_KEY] = ((context.Record[LEFT_KEY] or 1) :: number) - 1
			ServerShot.getShots(context, SHOT.Lifetime)[launch.Id] = {
				Origin = launch.Origin,
				Direction = launch.Direction.Unit,
				LaunchTime = os.clock(),
			}
		end
	end)
	:Guard(BINDINGS.Hit, function(context: ServerContext): boolean
		local hit = context.read(BINDINGS.Hit)
		local shot = if hit then ServerShot.getShots(context, SHOT.Lifetime)[hit.ShotId] else nil
		if not hit or not shot then
			return false
		end
		local target = hit.Target
		if target == context.Character or not target:FindFirstChildWhichIsA("Humanoid") then
			return false
		end
		return ServerShot.getIfReached(shot, target, SHOT)
	end)
	-- each is spent on whoever it ran into first: all of a throw can land on the same one
	:On(
		BINDINGS.Hit,
		function(context: ServerContext)
			local hit = context.read(BINDINGS.Hit)
			if hit then
				ServerShot.getShots(context, SHOT.Lifetime)[hit.ShotId] = nil
				context.VFX.fire(Attack, { Target = hit.Target, Amount = power.Damage })
			end
		end
	)
	-- the player's own machine shows them all of it right away, this is for everybody else
	:FireClient(
		BINDINGS.Launch,
		ClientVFXDefinition.Bolt,
		function(context: ServerContext): ClientVFXType.Bolt
			return ShotFactory.getBolt(SHOT, context.read(BINDINGS.Launch) :: ShotFactory.Launch, context.Color)
		end,
		{ Audience = "Others", Range = SHOT.Speed * SHOT.Lifetime }
	)
	:FireClient(BINDINGS.Ready, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = "Clink" }
	end, { Audience = "Others", Range = SOUND_RANGE })
	:FireClient(BINDINGS.Add, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = "Clink" }
	end, { Audience = "Others", Range = SOUND_RANGE })
	:FireClient(BINDINGS.Throw, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = "Fling" }
	end, { Audience = "Others", Range = SOUND_RANGE })
	:Build()
