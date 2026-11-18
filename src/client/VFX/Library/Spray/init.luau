--!strict
-- Services
local RunService = game:GetService("RunService")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Properties = ClientVFXType.Spray
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.state(ClientVFXDefinition.Spray, function(props: Properties, scope: ClientScope)
	local character = scope.Character
	local limbs: { BasePart } = {}
	for _, name in props.Limbs do
		local limb = character and character:FindFirstChild(name)
		if limb and limb:IsA("BasePart") then
			table.insert(limbs, limb)
		end
	end
	-- every machine lets them fly from where it has the limbs itself: only the one of the avatar is told what its
	-- own run into, to everybody else they're something to look at
	local function fire()
		for _, limb in limbs do
			local cframe = limb.CFrame * props.Turn
			scope.fire(ClientVFXDefinition.Bolt, {
				Origin = cframe.Position,
				Direction = cframe.LookVector,
				Speed = props.Speed,
				Lifetime = props.Lifetime,
				Gravity = props.Gravity,
				Size = props.Size,
				Color = props.Color,
				Material = props.Material,
				Mesh = props.Mesh,
				MeshScale = props.MeshScale,
				OnHit = props.OnHit,
			})
		end
	end
	fire()
	local elapsed = 0
	local connection = RunService.Heartbeat:Connect(function(deltaTime: number)
		elapsed += deltaTime
		-- a frame that took long doesn't make up for the rounds it missed
		if elapsed >= props.Interval then
			elapsed %= props.Interval
			fire()
		end
	end)
	return function()
		connection:Disconnect()
	end
end)
