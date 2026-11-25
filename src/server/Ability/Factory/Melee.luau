--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local Attack = require("@game/ServerScriptService/Server/VFX/Library/Attack")
local BodyUtil = require("@game/ReplicatedStorage/Shared/Util/Body")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local MeleeFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Melee")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Reach = require("@game/ReplicatedStorage/Shared/VFX/Library/Reach")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- Constants
-- studs everybody else hears a weapon from
local SOUND_RANGE = 150
-- studs a target may be further off than the reach: the two sides never see an avatar in quite the same spot
local REACH_TOLERANCE = 4
-- what a swing keeps of who it already hit
local TARGETS_KEY = "Targets"
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- the server half of a melee ability: a swing costs energy, everybody else gets to see + hear it + a hit the client
-- claims only lands if the server finds the target within reach
Module.new = function(ability: MeleeFactory.Ability): AbilityBuilder.ServerBuilder
	local layout = ability.Layout
	local bindings = layout.Bindings
	local shared = ability.Config
	local powerRes = PowerDefinition.get(layout.Id)
	assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
	local power = powerRes.Value
	local builder = AbilityBuilder.newServer(layout)
		:Guard(bindings.Swing, function(context: ServerContext): boolean
			return context.VFX.fire(SpendEnergy, { Amount = power.EnergyCost })
		end)
		:Guard(bindings.Hit, function(context: ServerContext): boolean
			local hit = context.read(bindings.Hit)
			local targets = (context.Memory[TARGETS_KEY] or {}) :: { [Model]: true }
			context.Memory[TARGETS_KEY] = targets
			if not hit or targets[hit.Target] or not hit.Target:FindFirstChildWhichIsA("Humanoid") then
				return false
			end
			-- a swing that's had its fill of them takes no more, whatever the client makes of it
			if shared.MaxTargets then
				local targetCount = 0
				for _ in targets do
					targetCount += 1
				end
				if targetCount >= shared.MaxTargets then
					return false
				end
			end
			targets[hit.Target] = true
			return context.VFX.fire(Reach, {
				Position = BodyUtil.getAimPosition(hit.Target, context.Character:GetPivot().Position),
				Range = shared.Reach + REACH_TOLERANCE,
			})
		end)
		:On(bindings.Hit, function(context: ServerContext)
			local hit = context.read(bindings.Hit)
			if hit then
				context.VFX.fire(Attack, { Target = hit.Target, Amount = power.Damage })
			end
		end)

	-- the player's own machine shows them their weapon + lets them hear it right away, this is for everybody else
	for _, prop in shared.Props do
		builder = builder:RunClient(
			bindings.Hold,
			ClientVFXDefinition.Prop,
			function(context: ServerContext): ClientVFXType.Prop
				return MeleeFactory.getProp(prop, context.Color)
			end,
			{ Audience = "Others" }
		)
	end
	local streaks: { ClientVFXType.Streak } = shared.Streaks or {}
	for _, streak in streaks do
		builder = builder:RunClient(
			bindings.Hold,
			ClientVFXDefinition.Streak,
			function(context: ServerContext): ClientVFXType.Streak
				return MeleeFactory.getStreak(streak, context.Color)
			end,
			{ Audience = "Others" }
		)
	end
	for binding, sound in MeleeFactory.getSounds(ability) do
		builder = builder:FireClient(binding, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
			return sound
		end, { Audience = "Others", Range = SOUND_RANGE })
	end

	return builder
end

return Module
