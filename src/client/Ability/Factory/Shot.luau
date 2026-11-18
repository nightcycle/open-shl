--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local ShotFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Shot")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ClientContext = AbilityType.ClientContext
-- what only the player who shoots needs to know
export type Config = {
	CastAnimation: VFXAssetDefinition.AnimationKey, -- from the click on, the shot leaves part-way through it
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
	local builder = AbilityBuilder.newClient(layout)

	-- the server has the last word on the energy, a cast it's sure to turn down isn't started on
	builder:Guard(bindings.Cast, function(context: ClientContext): boolean
		local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
		if BUILD_CONFIG.ENERGY_ENABLED and energy < energyCost then
			context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
			return false
		end
		return true
	end)
	builder:Fire(bindings.Cast, ClientVFXDefinition.AnimationOnce, function(): ClientVFXType.AnimationOnce
		return { Animation = config.CastAnimation }
	end)

	builder:On(bindings.Release, function(context: ClientContext)
		local limb = context.Character:FindFirstChild(shared.Limb)
		if not limb or not limb:IsA("BasePart") then
			return
		end
		-- the shot goes where the player pointed as they clicked, wherever they point by the time it leaves
		local aim = context.Aim or context.getAim()
		local offset = aim.Position - limb.Position
		-- pointed right at the limb there's no telling where to, the shot goes where the avatar looks
		local direction = if offset.Magnitude > MIN_AIM_DISTANCE
			then offset.Unit
			else context.Character:GetPivot().LookVector
		local id = ((context.Record[COUNT_KEY] or 0) :: number) + 1
		context.Record[COUNT_KEY] = id
		context.raise(bindings.Launch, {
			Id = id,
			-- half its length ahead of the limb, so none of it starts out behind it
			Origin = limb.Position + direction * shared.Size.Z / 2,
			Direction = direction,
		})
	end)

	builder:Fire(bindings.Launch, ClientVFXDefinition.Bolt, function(context: ClientContext): ClientVFXType.Bolt
		local launch = context.read(bindings.Launch) :: ShotFactory.Launch
		local bolt = ShotFactory.getBolt(shared, launch, context.Color)
		bolt.OnHit = function(result: RaycastResult)
			local target = getCharacter(result.Instance)
			if target then
				context.raise(bindings.Hit, { ShotId = launch.Id, Target = target })
			end
		end
		return bolt
	end)

	return builder
end

return Module
