--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local Barrier = require("@game/ServerScriptService/Server/VFX/Library/Barrier")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ForceField = require("@game/ReplicatedStorage/Shared/Ability/Library/Special/ForceField")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Reach = require("@game/ReplicatedStorage/Shared/VFX/Library/Reach")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- Constants
-- studs everybody else hears a wall go up from
local SOUND_RANGE = 150
-- studs from the avatar a wall is put up at most. a pointer gets 1000 from the camera, which stands back from the
-- avatar: nothing a player can really point at is turned down, a spot made up across the map is
local MAX_RANGE = 1200
local WALL_SIZE = Vector3.new(7, 7, 0.6)
-- the wall stands on the spot rather than around it
local WALL_OFFSET = Vector3.new(0, WALL_SIZE.Y / 2, 0)
-- seconds the wall stands at full strength + seconds it takes to go after that
local WALL_LIFETIME = 2
local WALL_FADE_DURATION = 3.2
-- studs the wall has to be off whoever it's turned to: there's no facing what's right where it stands
local MIN_FACING_DISTANCE = 0.01
-- Variables
-- References
-- Private Functions
-- stood on the spot, turned to the head of whoever put it up
local function getWallCFrame(character: Model, spot: Vector3): CFrame
	local middle = spot + WALL_OFFSET
	local head = character:FindFirstChild("Head")
	local eye = if head and head:IsA("BasePart") then head.Position else character:GetPivot().Position
	if (eye - middle).Magnitude < MIN_FACING_DISTANCE then
		return CFrame.new(middle)
	end
	return CFrame.lookAt(middle, eye)
end
-- Class
local layout = ForceField.Layout
local bindings = layout.Bindings
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local power = powerRes.Value
local colorOpt = PowerDefinition.getColor(power, nil)
assert(colorOpt.IsSome, `"{layout.Id}" has no color to fall back on`)
local defaultColor = colorOpt.Value
return AbilityBuilder
	.newServer(layout)
	:Guard(bindings.Cast, function(context: ServerContext): boolean
		return context.VFX.fire(SpendEnergy, { Amount = power.EnergyCost })
	end)
	-- the wall goes where the pointer was as the button went down. that's the client's word: a spot out of range is
	-- turned down + the cast ends without a wall
	:Guard(
		bindings.Rise,
		function(context: ServerContext): boolean
			local aim = context.Aim
			return aim ~= nil and context.VFX.fire(Reach, { Position = aim.Position, Range = MAX_RANGE })
		end
	)
	:Fire(bindings.Rise, Barrier, function(context: ServerContext): Barrier.Properties
		local aim = context.Aim :: AbilityType.Aim
		return {
			CFrame = getWallCFrame(context.Character, aim.Position),
			Size = WALL_SIZE,
			Color = context.Color or defaultColor,
			Lifetime = WALL_LIFETIME,
			FadeDuration = WALL_FADE_DURATION,
		}
	end)
	-- the player's own machine lets them hear it right away, this is for everybody else
	:FireClient(
		bindings.Rise,
		ClientVFXDefinition.Sound,
		function(): ClientVFXType.Sound
			return { Sound = ForceField.Sound }
		end,
		{ Audience = "Others", Range = SOUND_RANGE }
	)
	:Build()
