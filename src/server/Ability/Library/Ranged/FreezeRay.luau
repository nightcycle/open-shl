--!strict
-- Services
-- Packages
-- Modules
local Freeze = require("@game/ServerScriptService/Server/VFX/Library/Freeze")
local FreezeRay = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/FreezeRay")
local RayFactory = require("@game/ServerScriptService/Server/Ability/Factory/Ray")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ServerContext = AbilityType.ServerContext
-- Constants
-- seconds whoever it hurt neither walks nor jumps
local HOLD_DURATION = 5
-- seconds the ice is in the way of whatever comes next: it's shrunk away a second before
local BLOCK_DURATION = 7
-- the ice is the color of the ray
local ICE = FreezeRay.Config.Beams[1].Color
-- Variables
-- References
-- Private Functions
-- Class
-- only who the ray hurt is frozen: the freeze follows a hit that landed. the ice around them is the server's, so
-- nothing reaches them until it's gone, the next ray of whoever froze them included
return RayFactory.new(FreezeRay, function(context: ServerContext, target: Model): boolean?
	return context.VFX.fire(Freeze, {
		Target = target,
		Duration = HOLD_DURATION,
		BlockDuration = BLOCK_DURATION,
		Block = {
			Size = Vector3.new(5, 7, 5),
			Offset = CFrame.new(0, 1, 0),
			Color = ICE,
			Material = Enum.Material.Ice,
			Transparency = 0.3,
			GrowDuration = 1,
		},
	})
end):Build()
