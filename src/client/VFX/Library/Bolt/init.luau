--!strict
-- Services
local Workspace = game:GetService("Workspace")
-- Packages
-- Modules
local ClientVFX = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX")
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local Projectile = require("@game/ReplicatedStorage/Shared/VFX/Library/Projectile")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
local VFXType = require("@game/ReplicatedStorage/Shared/Type/VFX")
type ClientScope = VFXType.ClientScope
type Handle = VFXType.Handle
type Properties = ClientVFXType.Bolt
-- Constants
local BOLT_NAME = "Bolt"
-- how long what's left of a shot that landed takes to burn out
local FADE_DURATION = 3
-- a flame burns up the part it's on, turned like this it trails behind the shot instead
local FLAME_TURN = CFrame.Angles(math.pi / 2, 0, 0)
-- Variables
-- References
-- Private Functions
-- Class
return ClientVFX.event(ClientVFXDefinition.Bolt, function(props: Properties, scope: ClientScope)
	local direction = props.Direction.Unit
	local turn = if props.FireSize then FLAME_TURN else CFrame.identity
	local part = Instance.new("Part")
	part.Name = BOLT_NAME
	part.Material = Enum.Material.Neon
	part.Size = props.Size
	part.Color = props.Color
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CFrame = CFrame.lookAt(props.Origin, props.Origin + direction) * turn
	local fire: Fire? = nil
	if props.FireSize then
		-- a flame flies on its own, the part that carries it stays out of sight
		part.Transparency = 1
		local newFire = Instance.new("Fire")
		newFire.Heat = 14
		newFire.Size = props.FireSize
		newFire.Color = props.Color
		newFire.SecondaryColor = props.Color
		newFire.Parent = part
		fire = newFire
	end
	part.Parent = Workspace

	local handle: Handle
	local function land()
		handle.Stop()
		if fire then
			fire.Enabled = false
		else
			part.Transparency = 1
		end
		task.delay(FADE_DURATION, function()
			part:Destroy()
		end)
	end
	handle = scope.start(Projectile, {
		Origin = props.Origin,
		Direction = direction,
		Speed = props.Speed,
		Lifetime = props.Lifetime,
		OnStep = function(position: Vector3)
			part.CFrame = CFrame.lookAt(position, position + direction) * turn
		end,
		OnHit = function(result: RaycastResult)
			land()
			if props.OnHit then
				props.OnHit(result)
			end
		end,
		OnExpired = land,
	})
end)
