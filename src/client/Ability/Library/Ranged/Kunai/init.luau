--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Kunai = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/Kunai")
local ShotFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Shot")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientContext = AbilityType.ClientContext
type Handle = VFXType.Handle
-- Constants
local BINDINGS = Kunai.Layout.Bindings
local SHOT = Kunai.Config
-- how many the hand holds
local COUNT_KEY = "Count"
-- when the first of them got there
local LOAD_TIME_KEY = "LoadTime"
-- what's shown in the hand
local PROPS_KEY = "Props"
-- how many the character threw so far, the next one goes by it
local SHOT_COUNT_KEY = "ShotCount"
-- studs the spot pointed at has to be off the hand for the throw to be headed there
local MIN_AIM_DISTANCE = 0.01
-- Variables
-- References
-- Private Functions
local function getCharacter(inst: Instance): Model?
	local model = inst:FindFirstAncestorWhichIsA("Model")
	while model do
		if model:FindFirstChildWhichIsA("Humanoid") then
			return model
		end
		model = model:FindFirstAncestorWhichIsA("Model")
	end
	return nil
end

local function getCount(context: ClientContext): number
	return (context.Record[COUNT_KEY] or 0) :: number
end

local function addProp(context: ClientContext)
	local handles = context.Record[PROPS_KEY] :: { Handle }?
	if handles then
		table.insert(handles, context.VFX.start(ClientVFXDefinition.Prop, Kunai.getProp(#handles + 1)))
	end
end

local function getClink(): ClientVFXType.Sound
	return { Sound = "Clink" }
end
-- Class
-- the client half of the kunai: the player sees what they take in the hand + what they throw the moment they do. their
-- machine counts the hand, says where each of a throw flies + notices who it runs into
return AbilityBuilder
	.newClient(Kunai.Layout)
	:On(BINDINGS.Ready, function(context: ClientContext)
		context.Record[COUNT_KEY] = 1
		context.Record[LOAD_TIME_KEY] = os.clock()
	end)
	:Fire(BINDINGS.Ready, ClientVFXDefinition.Sound, getClink)
	-- the server turned the first one down: the hand is empty again
	:Undo(
		BINDINGS.Ready,
		function(context: ClientContext)
			context.Record[COUNT_KEY] = 0
		end
	)
	-- a click that's too late to be one more + too early to throw does nothing
	:Guard(
		BINDINGS.Add,
		function(context: ClientContext): boolean
			local loadTime = (context.Record[LOAD_TIME_KEY] or 0) :: number
			return Kunai.getIfAdding(getCount(context), os.clock() - loadTime)
		end
	)
	:On(BINDINGS.Add, function(context: ClientContext)
		context.Record[COUNT_KEY] = getCount(context) + 1
		addProp(context)
	end)
	:Fire(BINDINGS.Add, ClientVFXDefinition.Sound, getClink)
	:While(BINDINGS.Load, function(context: ClientContext): VFXType.Cleanup
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
	:On(BINDINGS.Throw, function(context: ClientContext)
		local count = getCount(context)
		context.Record[COUNT_KEY] = 0
		local limb = context.Character:FindFirstChild(SHOT.Limb)
		if not limb or not limb:IsA("BasePart") then
			return
		end
		local from = limb.Position
		local aim = context.Aim or context.getAim()
		local offset = aim.Position - from
		-- pointed right at the hand there's no telling where to, they go where the avatar looks
		local ahead = if offset.Magnitude > MIN_AIM_DISTANCE
			then offset.Unit
			else context.Character:GetPivot().LookVector
		for index = 1, count do
			local direction = Kunai.getDirection(ahead, index)
			local id = ((context.Record[SHOT_COUNT_KEY] or 0) :: number) + 1
			context.Record[SHOT_COUNT_KEY] = id
			context.raise(BINDINGS.Launch, {
				Id = id,
				-- half its length ahead of the hand, so none of it starts out behind it
				Origin = from + direction * SHOT.Size.Z / 2,
				Direction = direction,
			})
		end
	end)
	:Fire(BINDINGS.Throw, ClientVFXDefinition.AnimationOnce, function(): ClientVFXType.AnimationOnce
		return { Animation = "PowerShot" }
	end)
	:Fire(BINDINGS.Throw, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = "Fling" }
	end)
	:On(BINDINGS.Sheathe, function(context: ClientContext)
		context.Record[COUNT_KEY] = 0
	end)
	-- only somebody one of them runs into is worth a word to the server
	:Fire(
		BINDINGS.Launch,
		ClientVFXDefinition.Bolt,
		function(context: ClientContext): ClientVFXType.Bolt
			local launch = context.read(BINDINGS.Launch) :: ShotFactory.Launch
			local bolt = ShotFactory.getBolt(SHOT, launch, context.Color)
			bolt.OnHit = function(result: RaycastResult)
				local target = getCharacter(result.Instance)
				if target then
					context.raise(BINDINGS.Hit, { ShotId = launch.Id, Target = target })
				end
			end
			return bolt
		end
	)
	:Build()
