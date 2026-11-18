--!strict
-- Services
-- Packages
local IndexUtil = require("@game/ReplicatedStorage/Packages/IndexUtil")
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local SuperSpeed = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/SuperSpeed")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type ClientContext = AbilityType.ClientContext
-- Constants
-- studs a second the avatar runs at
local WALK_SPEED = 80
-- the pond of the park, a map without it has nothing to run across
local WATER_PATH = "game/Workspace/Map/buildings/ModelGround/ParkGround/GleamWater"
-- Variables
-- References
-- Private Functions
-- Class
local layout = SuperSpeed.Layout
local bindings = layout.Bindings
-- the client half of the super speed: the avatar is the player's own to move, so how fast it runs + what it runs
-- across is all here, everybody else sees where it ends up
return AbilityBuilder.newClient(layout)
	:Run(bindings.Sprint, ClientVFXDefinition.WalkSpeed, function(): ClientVFXType.WalkSpeed
		return { WalkSpeed = WALK_SPEED }
	end)
	:Run(bindings.Sprint, ClientVFXDefinition.SoundLoop, function(): ClientVFXType.SoundLoop
		return { Sound = SuperSpeed.Config.Sound }
	end)
	:While(bindings.Skim, function(context: ClientContext)
		local water = IndexUtil.findFirstPath(WATER_PATH)
		if not water or not water:IsA("BasePart") then
			return function() end
		end
		return context.VFX.start(ClientVFXDefinition.Skim, { Part = water }).Stop
	end)
	:Build()
