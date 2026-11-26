--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local AttributeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Attribute")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local ModeDefinition = require("@game/ReplicatedStorage/Shared/Definition/Mode")
local PlayAreaDefinition = require("@game/ReplicatedStorage/Shared/Definition/PlayArea")
local PowerDefinition = require("@game/ReplicatedStorage/Shared/Definition/Power")
local Reach = require("@game/ReplicatedStorage/Shared/VFX/Library/Reach")
local Teleport = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/Teleport")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ClientContext = AbilityType.ClientContext
-- Constants
-- the middle of the avatar ends up this far off the spot, so it stands on it rather than in it
local STANDING_OFFSET = Vector3.new(0, 3, 0)
-- where the avatar stood as it jumped, a jump the server turns down is taken back to it
local ORIGIN_KEY = "Origin"
-- Variables
-- References
-- Private Functions
-- Class
local layout = Teleport.Layout
local bindings = layout.Bindings
local config = Teleport.Config
-- where the click sends the avatar from where it stands
local function getPosition(context: ClientContext): Vector3
	return Teleport.getPosition(context.Character:GetPivot().Position, (context.Aim or context.getAim()).Position)
end
local powerRes = PowerDefinition.get(layout.Id)
assert(powerRes.IsOk, `no power is registered as "{layout.Id}"`)
local energyCost = powerRes.Value.EnergyCost
-- the client half of the teleport: the avatar is the player's own to move, so it's gone the moment they click
return AbilityBuilder
	.newClient(layout)
	-- the server has the last word on the energy, a jump it's sure to turn down isn't made
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
	-- neither out of a seat nor to a spot that's out of range or off the map. one that was brought back to the range
	-- is within it, but for what's lost in the sum
	:Guard(
		bindings.Cast,
		function(context: ClientContext): boolean
			local position = getPosition(context)
			local humanoid = context.Character:FindFirstChildWhichIsA("Humanoid")
			return humanoid ~= nil
				and humanoid.SeatPart == nil
				and PlayAreaDefinition.getIfInside(position)
				and (config.IsClamped or context.VFX.fire(Reach, { Position = position, Range = config.Range }))
		end
	)
	:On(bindings.Cast, function(context: ClientContext)
		context.Record[ORIGIN_KEY] = context.Character:GetPivot().Position
	end)
	:Fire(bindings.Cast, ClientVFXDefinition.Warp, function(context: ClientContext): ClientVFXType.Warp
		return { Position = getPosition(context) + STANDING_OFFSET, IsHeadingKept = config.IsHeadingKept }
	end)
	:Fire(bindings.Cast, ClientVFXDefinition.Sound, function(): ClientVFXType.Sound
		return { Sound = config.Sound }
	end)
	:Undo(bindings.Cast, function(context: ClientContext)
		local origin = context.Record[ORIGIN_KEY]
		if typeof(origin) == "Vector3" then
			context.VFX.fire(ClientVFXDefinition.Warp, { Position = origin, IsHeadingKept = config.IsHeadingKept })
		end
	end)
	:Build()
