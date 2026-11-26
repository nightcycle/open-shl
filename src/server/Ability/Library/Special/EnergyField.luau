--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local Barrier = require("@game/ServerScriptService/Server/VFX/Library/Barrier")
local Boxscan = require("@game/ReplicatedStorage/Shared/VFX/Library/Boxscan")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local EnergyField = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/EnergyField")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- Constants
-- studs everybody else hears a field thrown + stick from
local SOUND_RANGE = 150
-- studs a click has to be off the avatar to point anywhere
local MIN_AIM_DISTANCE = 0.01
-- how much of a direction has to run along the ground for a wall to face it: one thrown straight up or down faces
-- the way the avatar does
local MIN_FLAT_SHARE = 0.01
-- seconds a field has to be in the air for to be worth showing on its way
local MIN_FLIGHT_DURATION = 0.05
-- Variables
-- References
-- Private Functions
-- the wall stands upright whatever it's thrown at: this is the way along the ground it faces
local function getFacing(direction: Vector3, character: Model): Vector3
	local flat = Vector3.new(direction.X, 0, direction.Z)
	if flat.Magnitude < MIN_FLAT_SHARE then
		local look = character:GetPivot().LookVector
		flat = Vector3.new(look.X, 0, look.Z)
	end
	return if flat.Magnitude < MIN_FLAT_SHARE then Vector3.zAxis else flat.Unit
end
-- Class
local layout = EnergyField.Layout
local bindings = layout.Bindings
local config = EnergyField.Config
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local power = powerRes.Value
-- the server half of the field: all of it. the click only says which way, how far the field gets is looked up in
-- the world the server has + the wall is made here, so it's in the way of everybody
return AbilityBuilder
	.newServer(layout)
	:Guard(bindings.Cast, function(context: ServerContext): boolean
		return context.VFX.fire(SpendEnergy, { Amount = power.EnergyCost })
	end)
	:On(bindings.Cast, function(context: ServerContext)
		local aim = context.Aim
		if not aim then
			return
		end
		local character = context.Character
		local origin = character:GetPivot().Position
		local offset = aim.Position - origin
		if offset.Magnitude < MIN_AIM_DISTANCE then
			return
		end
		local direction = offset.Unit
		local position = origin + direction * config.Start
		local start = CFrame.lookAt(position, position + getFacing(direction, character))
		local color = context.Color or config.Color
		-- whoever is in its way is flown through, it's the world it sticks to. one that sets out in the world sticks
		-- where it is
		local scan = context.VFX.fire(Boxscan, {
			CFrame = start,
			Size = config.Size,
			Direction = direction,
			Range = config.Speed * config.Lifetime,
			IsPassingCharacters = true,
		})
		local duration = scan.Distance / config.Speed
		if duration > MIN_FLIGHT_DURATION then
			local bolt: ClientVFXType.Bolt = {
				Origin = position,
				Direction = direction,
				Speed = config.Speed,
				Lifetime = duration,
				Size = config.Size,
				Color = color,
				-- a shot points the way it flies, this one stays upright
				Turn = CFrame.lookAt(Vector3.zero, direction):Inverse() * start.Rotation,
			}
			context.VFX.fireClient(ClientVFXDefinition.Bolt, bolt, { Range = config.Speed * config.Lifetime })
		end
		-- one that ran into nothing all its time is never more than what was seen of it
		if not scan.Instance then
			return
		end
		local function land()
			-- it has faded for as long as it flew
			local share = duration / config.Lifetime
			context.VFX.fire(Barrier, {
				CFrame = start + direction * scan.Distance,
				Size = config.Size,
				Color = color,
				Lifetime = 0,
				FadeDuration = config.Lifetime - duration,
				Transparency = config.Transparency + (config.EndTransparency - config.Transparency) * share,
				EndTransparency = config.EndTransparency,
			})
			context.VFX.fireClient(ClientVFXDefinition.Sound, { Sound = config.LandSound }, { Range = SOUND_RANGE })
		end
		if duration > 0 then
			task.delay(duration, land)
		else
			land()
		end
	end)
	-- the player's own machine lets them hear it right away, this is for everybody else
	:FireClient(
		bindings.Cast,
		ClientVFXDefinition.Sound,
		function(): ClientVFXType.Sound
			return { Sound = config.CastSound }
		end,
		{ Audience = "Others", Range = SOUND_RANGE }
	)
	:Build()
