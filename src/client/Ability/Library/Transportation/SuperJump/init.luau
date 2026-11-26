--!strict
-- Services
-- Packages
-- Modules
local AbilityBuilder = require("@game/ReplicatedStorage/Shared/Ability/Builder")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local SuperJump = require("@game/ReplicatedStorage/Shared/Ability/Library/Transportation/SuperJump")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientContext = AbilityType.ClientContext
type Handle = VFXType.Handle
-- Constants
-- seconds an avatar has to have been down for before a leap counts as over: it's off the ground again right away
-- where it only brushed something
local LANDING_DELAY = 0.1
-- Variables
-- References
-- Private Functions
-- Class
local layout = SuperJump.Layout
local bindings = layout.Bindings
local config = SuperJump.Config
-- the client half of the super jump: the avatar is the player's own to move, so how it leaves the ground + comes
-- back down is all here, everybody else sees where it ends up
local builder = AbilityBuilder.newClient(layout)
local jumpPower = config.JumpPower
if jumpPower then
	builder = builder:Run(bindings.Hold, ClientVFXDefinition.JumpPower, function(): ClientVFXType.JumpPower
		return { JumpPower = jumpPower }
	end)
end
local float = config.Float
if float then
	builder = builder:Run(bindings.Hold, ClientVFXDefinition.Float, function(): ClientVFXType.Float
		return { Share = float }
	end)
end
local airSpeed = config.AirSpeed
if airSpeed then
	-- a leap carries the avatar as fast as a run would, from the jump until it's down again
	builder = builder:While(bindings.Hold, function(context: ClientContext)
		local humanoid = context.Character:FindFirstChildWhichIsA("Humanoid")
		if not humanoid then
			return function() end
		end
		local handle: Handle? = nil
		local landing: thread? = nil
		local function land()
			landing = nil
			local state = humanoid:GetState()
			if handle and state ~= Enum.HumanoidStateType.Jumping and state ~= Enum.HumanoidStateType.Freefall then
				handle.Stop()
				handle = nil
			end
		end
		local connection = humanoid.StateChanged:Connect(
			function(_: Enum.HumanoidStateType, state: Enum.HumanoidStateType)
				if state == Enum.HumanoidStateType.Jumping then
					if not handle then
						handle = context.VFX.start(ClientVFXDefinition.WalkSpeed, { WalkSpeed = airSpeed })
					end
				elseif state ~= Enum.HumanoidStateType.Freefall and handle and not landing then
					landing = task.delay(LANDING_DELAY, land)
				end
			end
		)
		return function()
			connection:Disconnect()
			if landing then
				task.cancel(landing)
			end
			if handle then
				handle.Stop()
			end
		end
	end)
end

return builder:Build()
