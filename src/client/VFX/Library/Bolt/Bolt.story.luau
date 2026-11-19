--!strict
--!native
_G.__REACT_MICROPROFILER_LEVEL = 10
-- Services
-- Packages
local UILabs = require("@game/ReplicatedStorage/DevPackages/UILabs")
-- Modules
local ClientVFXDefinition = require("@game/ReplicatedStorage/Shared/Definition/ClientVFX")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
local VFXStory = require("@game/StarterPlayer/StarterPlayerScripts/Client/VFX/Story")
-- Components
-- Hooks
-- Types
-- Constants
local LIGHTNING: { VFXAssetDefinition.ParticleKey } = { "LightningLeft", "LightningRight" }
-- Variables
-- References
-- Private Functions
-- Class
-- shot from the right hand of the user at the target, what it runs into is printed. with nothing for it to give off
-- it's the part itself that's seen, or its mesh. a roll of 0 leaves it turned the way it is by itself. it's heard
-- landing by the one sound every game has a row for
return VFXStory.newEventStory({
	Distance = UILabs.Slider(30, 4, 60, 1),
	Speed = UILabs.Slider(80, 5, 300, 5),
	Lifetime = UILabs.Slider(10, 0.5, 20, 0.5),
	Gravity = UILabs.Slider(0, 0, 250, 1),
	Width = UILabs.Slider(0.4, 0.1, 4, 0.1),
	Height = UILabs.Slider(0.4, 0.1, 4, 0.1),
	Length = UILabs.Slider(4, 0.5, 16, 0.5),
	Color = UILabs.Datatype.Color3(BrickColor.new("Bright orange").Color),
	HasFire = UILabs.Boolean(true),
	FireSize = UILabs.Slider(7, 2, 30, 0.5),
	FireHeat = UILabs.Slider(14, -25, 25, 1),
	SecondaryColor = UILabs.Datatype.Color3(BrickColor.new("Bright orange").Color),
	HasSparkles = UILabs.Boolean(false),
	HasLightning = UILabs.Boolean(false),
	HasMesh = UILabs.Boolean(false),
	MeshScale = UILabs.Slider(3, 0.5, 6, 0.5),
	Roll = UILabs.Slider(0, 0, 180, 5),
	IsSticking = UILabs.Boolean(false),
	HasLandSound = UILabs.Boolean(false),
}, function(stage: VFXStory.Stage, controls)
	local hand = stage.User:FindFirstChild("RightHand")
	local targetRoot = stage.Target.PrimaryPart
	if not hand or not hand:IsA("BasePart") or not targetRoot then
		return
	end
	local origin = hand.Position
	stage.ClientScope.fire(ClientVFXDefinition.Bolt, {
		Origin = origin,
		Direction = targetRoot.Position - origin,
		Speed = controls.Speed,
		Lifetime = controls.Lifetime,
		Gravity = controls.Gravity,
		Size = Vector3.new(controls.Width, controls.Height, controls.Length),
		Color = controls.Color,
		FireSize = if controls.HasFire then controls.FireSize else nil,
		FireHeat = controls.FireHeat,
		SecondaryColor = controls.SecondaryColor,
		HasSparkles = controls.HasSparkles,
		Particles = if controls.HasLightning then LIGHTNING else nil,
		Material = if controls.HasMesh then Enum.Material.SmoothPlastic else nil,
		Mesh = if controls.HasMesh then "ThrowingStar" :: VFXAssetDefinition.MeshKey else nil,
		MeshScale = Vector3.one * controls.MeshScale,
		Turn = if controls.Roll > 0 then CFrame.Angles(0, 0, math.rad(controls.Roll)) else nil,
		IsSticking = controls.IsSticking,
		LandSound = if controls.HasLandSound then "Slash" :: VFXAssetDefinition.SoundKey else nil,
		OnHit = function(result: RaycastResult)
			print(`hit: {result.Instance:GetFullName()}`)
		end,
	})
end)
