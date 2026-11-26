--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Projectile = require("@game/ReplicatedStorage/Shared/VFX/Library/Projectile")
local ShotFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Shot")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientContext = AbilityType.ClientContext
-- what only the player who shoots needs to know
export type Config = {
	-- from the click on, the shot leaves part-way through it. one that's charged leaves with it instead: how long the
	-- button is held for is anybody's guess. the avatar does nothing special without
	CastAnimation: VFXAssetDefinition.AnimationKey?,
}
-- Constants
-- how many shots the character let fly so far, the next one goes by it
local COUNT_KEY = "ShotCount"
-- studs the spot pointed at has to be off the limb for the shot to be headed there
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
-- Class
local Module = {}

-- the client half of a shot ability: the player sees their own cast + their own shot the moment it happens, their
-- machine is the one to say where the shot flies + to notice who it runs into
Module.new = function(ability: ShotFactory.Ability, config: Config): AbilityBuilder.ClientBuilder
	local layout = ability.Layout
	local bindings = layout.Bindings
	local shared = ability.Config
	local powerRes = PowerDefinition.get(layout.Id)
	assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
	local energyCost = powerRes.Value.EnergyCost
	local builder = AbilityBuilder
		.newClient(layout)
		-- the server has the last word on the energy, a cast it's sure to turn down isn't started on
		:Guard(
			bindings.Cast,
			function(context: ClientContext): boolean
				local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
				if ModeDefinition.getIfEnergyEnabled() and energy < energyCost then
					context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
					return false
				end
				return true
			end
		)
	local castAnimation = config.CastAnimation
	if castAnimation then
		builder = builder:Fire(
			if shared.IsCharged then bindings.Release else bindings.Cast,
			ClientVFXDefinition.AnimationOnce,
			function(): ClientVFXType.AnimationOnce
				return { Animation = castAnimation :: VFXAssetDefinition.AnimationKey }
			end
		)
	end
	builder = builder:On(bindings.Release, function(context: ClientContext)
		local limb = context.Character:FindFirstChild(shared.Limb)
		if not limb or not limb:IsA("BasePart") then
			return
		end
		local from = if shared.Offset then limb.CFrame:PointToWorldSpace(shared.Offset) else limb.Position
		-- the shot goes where the player pointed as they clicked, wherever they point by the time it leaves
		local aim = context.Aim or context.getAim()
		local offset = aim.Position - from
		-- pointed right at the limb there's no telling where to, the shot goes where the avatar looks
		local direction = if offset.Magnitude > MIN_AIM_DISTANCE
			then offset.Unit
			else context.Character:GetPivot().LookVector
		local id = ((context.Record[COUNT_KEY] or 0) :: number) + 1
		context.Record[COUNT_KEY] = id
		context.raise(bindings.Launch, {
			Id = id,
			-- half its length ahead of the limb, so none of it starts out behind it
			Origin = from + direction * shared.Size.Z / 2,
			Direction = direction,
		})
	end)

	-- only somebody a shot runs into is worth a word to the server, unless it makes something of wherever it lands
	local land = bindings.Land
	local function getOnHit(context: ClientContext, launch: ShotFactory.Launch): (result: RaycastResult) -> ()
		return function(result: RaycastResult)
			local target = getCharacter(result.Instance)
			if target then
				context.raise(bindings.Hit, { ShotId = launch.Id, Target = target })
			end
			if land then
				context.raise(land, { ShotId = launch.Id, Position = result.Position })
			end
		end
	end
	if shared.IsHidden then
		-- there's nothing of it to show, it's only flown to find out who it runs into
		builder = builder:On(bindings.Launch, function(context: ClientContext)
			local launch = context.read(bindings.Launch)
			if not launch then
				return
			end
			local onHit = getOnHit(context, launch)
			local handle: VFXType.Handle
			handle = context.VFX.start(Projectile, {
				Origin = launch.Origin,
				Direction = launch.Direction,
				Speed = shared.Speed,
				Lifetime = shared.Lifetime,
				Gravity = shared.Gravity,
				OnHit = function(result: RaycastResult)
					handle.Stop()
					onHit(result)
				end,
				OnExpired = function()
					handle.Stop()
				end,
			})
		end)
	else
		builder = builder:Fire(
			bindings.Launch,
			ClientVFXDefinition.Bolt,
			function(context: ClientContext): ClientVFXType.Bolt
				local launch = context.read(bindings.Launch) :: ShotFactory.Launch
				local bolt = ShotFactory.getBolt(shared, launch, context.Color)
				bolt.OnHit = getOnHit(context, launch)
				return bolt
			end
		)
	end

	-- not every shot is heard as it leaves
	local launchSound = shared.LaunchSound
	if launchSound then
		builder = builder:Fire(bindings.Launch, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
			return { Sound = launchSound :: VFXAssetDefinition.SoundKey }
		end)
	end

	return builder
end

return Module
