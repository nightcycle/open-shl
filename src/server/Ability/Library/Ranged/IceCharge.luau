--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local Attack = require("@game/ServerScriptService/Server/VFX/Library/Attack")
local BodyUtil = require("@game/ReplicatedStorage/Shared/Util/Body")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local CombatDefinition = require("@game/ReplicatedStorage/Shared/Definition/Combat")
local Freeze = require("@game/ServerScriptService/Server/VFX/Library/Freeze")
local IceCharge = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/IceCharge")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local ShotFactory = require("@game/ServerScriptService/Server/Ability/Factory/Shot")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- Constants
local BINDINGS = IceCharge.Layout.Bindings
-- studs from the landing the ice gets to: its biggest piece is as much as 8 across
local REACH = 4
-- seconds it takes to get there, the biggest piece is done growing by then
local GROW_DURATION = 2.3
-- studs past the ice the middle of somebody may be for it to have them: it only has to reach a limb
local MARGIN = 2
-- seconds between two looks at who the ice has got to
local LOOK_INTERVAL = 0.25
-- the highest seed a roll is made from
local MAX_SEED = 2 ^ 31 - 1
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

-- every character with its middle that close to a spot. a body nobody plays is held to the closest of it
local function getCharacters(position: Vector3, range: number): { Model }
	local found: { [Model]: true } = {}
	local characters: { Model } = {}
	for _, part in Workspace:GetPartBoundsInRadius(position, range) do
		local character = getCharacter(part)
		if not character or found[character] then
			continue
		end
		found[character] = true
		if (BodyUtil.getAimPosition(character, position) - position).Magnitude <= range then
			table.insert(characters, character)
		end
	end
	return characters
end
-- Class
local powerRes = PowerDefinition.get(IceCharge.Layout.Id)
assert(powerRes.IsOk, `no power is registered as "{IceCharge.Layout.Id}"`)
local power = powerRes.Value

-- the server half of the ice: the ball itself hurts nobody, what grows where it landed does. everybody is shown the
-- same ice. for as long as it's there the server looks at who it has got to by now: each of them is hurt once + only
-- who that landed on is held, for what's left of the ice. so nobody the rules keep from harm is held either: not
-- whoever let it go, a friend or somebody peaceful
return ShotFactory
	.new(IceCharge.Shot, function(context: ServerContext, position: Vector3)
		local frost = IceCharge.getFrost(position, Random.new():NextInteger(1, MAX_SEED))
		context.VFX.fireClient(ClientVFXDefinition.Frost, frost)
		local duration = frost.Lifetime
		local landTime = os.clock()
		local caught: { [Model]: true } = {}
		local function look()
			local age = os.clock() - landTime
			-- ice of somebody who's gone holds nobody new
			if age >= duration or not context.Character:IsDescendantOf(Workspace) then
				return
			end
			local range = REACH * math.min(age / GROW_DURATION, 1) + MARGIN
			for _, character in getCharacters(position, range) do
				if caught[character] or not CombatDefinition.getIfHostile(context.Character, character) then
					continue
				end
				caught[character] = true
				-- it doesn't send off who it's about to hold
				local isLanded = context.VFX.fire(Attack, { Target = character, Amount = power.Damage, IsStill = true })
				if isLanded then
					context.VFX.fire(Freeze, { Target = character, Duration = duration - age })
				end
			end
			task.delay(LOOK_INTERVAL, look)
		end
		look()
	end)
	:Clear(BINDINGS.Hit)
	-- a hand that's put away mid-way has nothing to let go of
	:On(BINDINGS.Sheathe, ShotFactory.cancel)
	-- the player's own machine shows them their hand filling right away, this is for everybody else
	:RunClient(
		BINDINGS.Charging,
		ClientVFXDefinition.Flame,
		function(): ClientVFXType.Flame
			return IceCharge.FLAME
		end,
		{ Audience = "Others" }
	)
	:RunClient(BINDINGS.Charging, ClientVFXDefinition.Prop, function(): ClientVFXType.Prop
		return IceCharge.BALL
	end, { Audience = "Others" })
	:Build()
