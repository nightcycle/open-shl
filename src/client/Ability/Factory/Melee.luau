--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local BUILD_CONFIG = require("@game/ReplicatedStorage/Generated/BUILD_CONFIG")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Hitbox = require("@game/ReplicatedStorage/Shared/VFX/Library/Hitbox")
local MeleeFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Melee")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientContext = AbilityType.ClientContext
type AnimationKey = VFXAssetDefinition.AnimationKey
-- what only the player who swings needs to know
export type Config = {
	DrawAnimation: AnimationKey?, -- as the weapon comes out + as it's put away
	SwingAnimations: { AnimationKey }, -- one of them at random with every swing
	IsRooted: boolean?, -- the avatar stands where it is for as long as a swing takes
}
-- Constants
-- Variables
local Rng = Random.new()
-- References
-- Private Functions
-- Class
local Module = {}

-- the client half of a melee ability: the player sees + hears their own swing the moment they click + their machine
-- is the one to notice who the weapon runs into
Module.new = function(ability: MeleeFactory.Ability, config: Config): AbilityBuilder.ClientBuilder
	local layout = ability.Layout
	local bindings = layout.Bindings
	local shared = ability.Config
	local powerRes = PowerDefinition.get(layout.Id)
	assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
	local energyCost = powerRes.Value.EnergyCost
	local builder = AbilityBuilder
		.newClient(layout)
		-- the server has the last word on the energy, a swing it's sure to turn down isn't started on
		:Guard(
			bindings.Swing,
			function(context: ClientContext): boolean
				local energy = AttributeDefinition.get(context.Character, AttributeDefinition.Energy)
				if BUILD_CONFIG.ENERGY_ENABLED and energy < energyCost then
					context.VFX.fire(ClientVFXDefinition.EnergyWarning, {})
					return false
				end
				return true
			end
		)
		:Fire(bindings.Swing, ClientVFXDefinition.AnimationOnce, function(): ClientVFXType.AnimationOnce
			return { Animation = config.SwingAnimations[Rng:NextInteger(1, #config.SwingAnimations)] }
		end)
		:While(bindings.Sweep, function(context: ClientContext)
			-- somebody two of the boxes run into is still only told of once
			local targets: { [Model]: true } = {}
			local handles: { VFXType.Handle } = {}
			for _, hitbox in shared.Hitboxes do
				local limb = context.Character:FindFirstChild(hitbox.Limb)
				if not limb or not limb:IsA("BasePart") then
					continue
				end
				table.insert(
					handles,
					context.VFX.start(Hitbox, {
						Part = limb,
						Size = hitbox.Size,
						Offset = hitbox.Offset,
						OnHit = function(target: Model)
							if not targets[target] then
								targets[target] = true
								context.raise(bindings.Hit, { Target = target })
							end
						end,
					})
				)
			end
			return function()
				for _, handle in handles do
					handle.Stop()
				end
			end
		end)

	for _, prop in shared.Props do
		builder = builder:Run(
			bindings.Hold,
			ClientVFXDefinition.Prop,
			function(context: ClientContext): ClientVFXType.Prop
				return MeleeFactory.getProp(prop, context.Color)
			end
		)
	end
	-- not every weapon is drawn with a flourish or heard as it's drawn, swung or put away
	local drawAnimation = config.DrawAnimation
	if drawAnimation then
		local function getProps(): ClientVFXType.AnimationOnce
			return { Animation = drawAnimation :: AnimationKey }
		end
		builder = builder
			:Fire(bindings.Draw, ClientVFXDefinition.AnimationOnce, getProps)
			:Fire(bindings.Sheathe, ClientVFXDefinition.AnimationOnce, getProps)
	end
	for binding, sound in MeleeFactory.getSounds(ability) do
		builder = builder:Fire(binding, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
			return { Sound = sound :: VFXAssetDefinition.SoundKey }
		end)
	end
	if config.IsRooted then
		builder = builder:Run(bindings.Sweep, ClientVFXDefinition.Root, function(): ClientVFXType.Root
			return {}
		end)
	end

	return builder
end

return Module
