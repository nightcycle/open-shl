--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local PlayAreaDefinition = require("@game/ReplicatedStorage/Shared/Definition/PlayArea")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Reach = require("@game/ReplicatedStorage/Shared/VFX/Library/Reach")
local SpendEnergy = require("@game/ServerScriptService/Server/VFX/Library/SpendEnergy")
local Teleport = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/Teleport")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ServerContext = AbilityType.ServerContext
-- Constants
-- studs everybody else hears an avatar arrive from
local SOUND_RANGE = 150
-- studs a spot may be further off than the range: the two sides never see an avatar in quite the same spot
local RANGE_TOLERANCE = 10
-- Variables
-- References
-- Private Functions
-- Class
local layout = Teleport.Layout
local bindings = layout.Bindings
local config = Teleport.Config
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
-- the server half of the teleport: a jump costs energy + everybody else gets to hear it. the avatar is moved by the
-- client of its player, where it ends up gets to the others by itself
return AbilityBuilder
	.newServer(layout)
	-- where to is the client's word: a spot that's out of range or off the map is turned down, so is a jump out of
	-- a seat. by the time the word is here the avatar may have left already, either end of the jump is within range
	:Guard(
		bindings.Cast,
		function(context: ServerContext): boolean
			local aim = context.Aim
			local humanoid = context.Character:FindFirstChildWhichIsA("Humanoid")
			return aim ~= nil
				and humanoid ~= nil
				and humanoid.SeatPart == nil
				and PlayAreaDefinition.getIfInside(aim.Position)
				and context.VFX.fire(Reach, { Position = aim.Position, Range = config.Range + RANGE_TOLERANCE })
		end
	)
	:Guard(bindings.Cast, function(context: ServerContext): boolean
		return context.VFX.fire(SpendEnergy, { Amount = energyCost })
	end)
	-- the player's own machine lets them hear it right away, this is for everybody else
	:FireClient(
		bindings.Cast,
		ClientVFXDefinition.Sound,
		function(): ClientVFXType.Sound
			return { Sound = config.Sound }
		end,
		{ Audience = "Others", Range = SOUND_RANGE }
	)
	:Build()
