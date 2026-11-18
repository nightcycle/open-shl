--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local Camouflage = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/Camouflage")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ClientContext = AbilityType.ClientContext
type Surface = Camouflage.Surface
-- Constants
-- studs past the spot pointed at the look for what's there goes on: the spot is on its skin, not inside of it
local SURFACE_DEPTH = 1
-- studs the spot pointed at has to be off the eye for there to be a way to look along
local MIN_AIM_DISTANCE = 0.01
-- whether the state the machine is in has a look on the avatar
local IS_DISGUISED_KEY = "IsDisguised"
-- Variables
-- References
-- Private Functions
-- what the player points at, as far as the avatar can take it on. nil for the sky
local function getSurface(character: Model, aim: AbilityType.Aim): Surface?
	local offset = aim.Position - aim.Origin
	if offset.Magnitude < MIN_AIM_DISTANCE then
		return nil
	end
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }
	local result = Workspace:Raycast(aim.Origin, offset.Unit * (offset.Magnitude + SURFACE_DEPTH), raycastParams)
	if not result then
		return nil
	end
	local inst = result.Instance
	if inst:IsA("Terrain") then
		-- the ground keeps its colors by material, water apart from the rest
		local material = result.Material
		return {
			Material = material,
			Color = if material == Enum.Material.Water then inst.WaterColor else inst:GetMaterialColor(material),
		}
	elseif inst:IsA("BasePart") then
		return { Material = inst.Material, Color = inst.Color }
	end
	return nil
end

local function getEnergy(context: ClientContext): number
	return AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
end
-- Class
local layout = Camouflage.Layout
local bindings = layout.Bindings
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
-- the client half of the camouflage: what the player points at is only known here, so their machine is the one to
-- say what the avatar takes on + shows it to them the moment they click
return AbilityBuilder
	.newClient(layout)
	-- the server has the last word on the energy, a cast it's sure to turn down isn't started on. with a look on
	-- that's no reason to warn: the click takes it off instead
	:Guard(
		bindings.Cast,
		function(context: ClientContext): boolean
			if BUILD_CONFIG.ENERGY_ENABLED and getEnergy(context) < energyCost then
				if not context.Memory[IS_DISGUISED_KEY] then
					context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
				end
				return false
			end
			return true
		end
	)
	:Fire(bindings.Cast, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Camouflage.CastSound }
	end)
	-- the avatar takes on what the player pointed at as they clicked. pointed at nothing there's no word to send:
	-- the cast runs out + leaves the avatar plain
	:On(
		bindings.Cast,
		function(context: ClientContext)
			local surface = getSurface(context.Character, context.Aim or context.getAim())
			if surface then
				context.raise(bindings.Blend, surface)
			end
		end
	)
	:On(bindings.Blend, function(context: ClientContext)
		context.Record[Camouflage.SurfaceKey] = context.read(bindings.Blend)
	end)
	:Run(bindings.Disguise, ClientVFXDefinition.Coat, function(context: ClientContext): ClientVFXType.Coat
		return context.Record[Camouflage.SurfaceKey] :: Surface
	end)
	:While(bindings.Disguise, function(context: ClientContext)
		context.Memory[IS_DISGUISED_KEY] = true
		return function() end
	end)
	-- the click a cast is turned down for takes the look off instead
	:Guard(
		bindings.Shed,
		function(context: ClientContext): boolean
			return BUILD_CONFIG.ENERGY_ENABLED and getEnergy(context) < energyCost
		end
	)
	:Fire(bindings.Shed, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Camouflage.ResetSound }
	end)
	:Fire(bindings.Fade, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = Camouflage.ResetSound }
	end)
	:Build()
