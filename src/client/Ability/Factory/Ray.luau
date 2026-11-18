--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Hitscan = require("@game/ReplicatedStorage/Shared/VFX/Library/Hitscan")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local RayFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Ray")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type Aim = AbilityType.Aim
type ClientContext = AbilityType.ClientContext
type AnimationKey = VFXAssetDefinition.AnimationKey
-- what only the player who shoots needs to know
export type Config = {
	HoldAnimation: AnimationKey, -- for as long as the tool is out
	CastAnimation: AnimationKey, -- from the click on
}
-- Constants
-- how many rays the character let go so far, the next one goes by it
local COUNT_KEY = "RayCount"
-- studs the spot pointed at has to be off the limb for the ray to be headed there
local MIN_AIM_DISTANCE = 0.01
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the client half of a ray ability: the player sees their own cast + their own beam the moment it happens, their
-- machine is the one to say where a ray leaves from + what's in its way. the server may find it ended sooner, the beam
-- is put right once its word is back
Module.new = function(ability: RayFactory.Ability, config: Config): AbilityBuilder.ClientBuilder
	local layout = ability.Layout
	local bindings = layout.Bindings
	local shared = ability.Config
	local powerRes = PowerDefinition.get(layout.Id)
	assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
	local energyCost = powerRes.Value.EnergyCost

	-- lets one ray go at what the player pointed at as they clicked, from wherever the limb is by now
	local function release(context: ClientContext, aim: Aim)
		local limb = context.Character:FindFirstChild(shared.Limb)
		if not limb or not limb:IsA("BasePart") then
			return
		end
		local from = if shared.Offset then limb.CFrame:PointToWorldSpace(shared.Offset) else limb.Position
		local offset = aim.Position - from
		-- pointed right at the limb there's no telling where to, the ray goes where the avatar looks
		local direction = if offset.Magnitude > MIN_AIM_DISTANCE
			then offset.Unit
			else context.Character:GetPivot().LookVector
		local hit = context.VFX.fire(Hitscan, { Origin = from, Direction = direction, Range = shared.Range })
		if not hit then
			return
		end
		local id = ((context.Record[COUNT_KEY] or 0) :: number) + 1
		context.Record[COUNT_KEY] = id
		context.raise(bindings.Fire, {
			Id = id,
			Origin = from,
			Direction = direction,
			-- a vector is only so exact: what's right at the end of the range can come back a hair past it
			Distance = math.min(hit.Distance, shared.Range),
			Target = hit.Target,
		})
	end

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
		:Run(bindings.Hold, ClientVFXDefinition.Animation, function(): ClientVFXType.Animation
			return { Animation = config.HoldAnimation }
		end)
		:Fire(bindings.Cast, ClientVFXDefinition.AnimationOnce, function(): ClientVFXType.AnimationOnce
			return { Animation = config.CastAnimation }
		end)
		:On(bindings.Cast, function(context: ClientContext)
			-- every ray of a cast goes where the player pointed as they clicked, wherever they point by the time
			-- it leaves
			local aim = context.Aim or context.getAim()
			local elapsed = 0
			for index = 1, RayFactory.getCount(shared) do
				local delay = RayFactory.getReleaseDelay(shared, index)
				if delay > elapsed then
					task.wait(delay - elapsed)
					elapsed = delay
				end
				release(context, aim)
			end
		end)

	for _, prop in shared.Props do
		builder = builder:Run(
			bindings.Hold,
			ClientVFXDefinition.Prop,
			function(context: ClientContext): ClientVFXType.Prop
				return RayFactory.getProp(shared, prop, context.Color)
			end
		)
	end

	-- every beam of a ray is an effect of its own
	for index in shared.Beams do
		builder = builder:Fire(
			bindings.Fire,
			ClientVFXDefinition.Beam,
			function(context: ClientContext): ClientVFXType.Beam
				local fire = context.read(bindings.Fire) :: RayFactory.Fire
				return RayFactory.getBeams(ability, fire, fire.Distance, context.Color, context.SecondaryColor)[index]
			end
		)
	end

	-- not every ray is heard as it leaves
	local fireSound = shared.FireSound
	if fireSound then
		builder = builder:Fire(bindings.Fire, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
			return { Sound = fireSound :: VFXAssetDefinition.SoundKey }
		end)
	end

	return builder
end

return Module
