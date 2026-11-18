--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local SuperSpeed = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/SuperSpeed")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ClientContext = AbilityType.ClientContext
type SoundKey = VFXAssetDefinition.SoundKey
-- Constants
-- the pond of the park, a map without it has nothing to run across
local WATER_PATH = "game/Workspace/Map/buildings/ModelGround/ParkGround/GleamWater"
-- Variables
-- References
-- Private Functions
-- Class
local layout = SuperSpeed.Layout
local bindings = layout.Bindings
local config = SuperSpeed.Config
-- the client half of the super speed: the avatar is the player's own to move, so how fast it runs + what it runs
-- across is all here, everybody else sees where it ends up
local builder = AbilityBuilder.newClient(layout)
	:Run(bindings.Sprint, ClientVFXDefinition.WalkSpeed, function(): ClientVFXType.WalkSpeed
		return { WalkSpeed = config.WalkSpeed }
	end)
-- not every game has wind around whoever runs, widens their view or has them leave something behind
local sound = config.Sound
if sound then
	builder = builder:Run(bindings.Sprint, ClientVFXDefinition.SoundLoop, function(): ClientVFXType.SoundLoop
		return { Sound = sound :: SoundKey }
	end)
end
local fieldOfView = config.FieldOfView
if fieldOfView then
	-- a camera is its player's own, nobody else has theirs widened
	builder = builder:Run(bindings.Sprint, ClientVFXDefinition.FieldOfView, function(): ClientVFXType.FieldOfView
		return fieldOfView
	end)
end
local wake = config.Wake
if wake then
	builder = builder:Run(
		bindings.Sprint,
		ClientVFXDefinition.Wake,
		function(context: ClientContext): ClientVFXType.Wake
			return {
				Color = context.Color or wake.Color,
				SecondaryColor = context.SecondaryColor or wake.SecondaryColor,
				Lifetime = wake.Lifetime,
				Depth = wake.Depth,
			}
		end
	)
end

return builder
	:While(bindings.Skim, function(context: ClientContext)
		local water = IndexUtil.findFirstPath(WATER_PATH)
		if not water or not water:IsA("BasePart") then
			return function() end
		end
		return context.VFX.start(ClientVFXDefinition.Skim, { Part = water }).Stop
	end)
	:Build()
