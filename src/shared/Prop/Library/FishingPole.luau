--!strict
-- Services
-- Packages
-- Modules
local PropDefinition = require("@game/ReplicatedStorage/Shared/Definition/Prop")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type AnimationKey = VFXAssetDefinition.AnimationKey
type MeshKey = VFXAssetDefinition.MeshKey
-- Constants
local ID = "fishing-pole"
-- the arm out in front, what a hand that holds anything used to do by itself
local HOLD_ANIMATION: AnimationKey = "GunHolding"
local POLE: ClientVFXType.Prop = table.freeze({
	Limb = "RightHand",
	Size = Vector3.new(5, 0.2, 0.2),
	-- of the hand from it, the way the old tool gripped it
	Offset = CFrame.new(-2.015, 0.011, 0.169, 0, 0, -1, -1, 0, 0, 0, 1, 0),
	Color = Color3.fromRGB(27, 42, 53),
	Material = Enum.Material.SmoothPlastic,
	Mesh = "FishingPole" :: "FishingPole",
	MeshScale = Vector3.one * 0.05,
})
-- where the line is tied, of the hand: near the far end of the pole
local TIP = POLE.Offset:Inverse() * Vector3.new(2.4, 0.1, 0)
-- studs of line there are while it hangs off the pole
local REST_LENGTH = 3
-- what a cast lets out, of how far off it lands
local SLACK = 1.15
-- the hook hangs by its eye: the old one was a mesh scaled through itself, which is the same mesh turned over
local END_TURN = CFrame.Angles(-math.pi / 2, 0, 0)
local END_MESH_SCALE = Vector3.new(0.25, 0.3, 0.25)
local SINKER: MeshKey = "Sinker"
-- what bites, each as likely as the next: half of them are silver
local FISH: { MeshKey } = table.freeze({ "FishGreen", "FishOrange", "FishSilver", "FishSilver" } :: { MeshKey })
-- Variables
-- References
-- Private Functions
-- Class
local definitionRes = PropDefinition.get(ID)
assert(definitionRes.IsOk, `no prop is registered as "{ID}"`)

-- the pole off the pad in the park: a click casts the line at what the pointer is on, the next reels it in. a cast
-- that lands on water has a fish on the hook, which gives nothing + is gone a moment after it's reeled in. where a
-- cast lands + what bites is the server's to say; the line + what hangs on it are drawn by whoever sees them
return table.freeze({
	Prop = definitionRes.Value,
	HoldAnimation = HOLD_ANIMATION,
	Pole = POLE,
	Tip = TIP,
	RestLength = REST_LENGTH,
	Slack = SLACK,
	-- studs from the avatar a cast may land at most: as far as the rays of the powers go. the old one had no end
	Reach = 500,
	-- seconds a fish that's reeled in stays on the hook
	FishDuration = 2,
	Fish = FISH,
	-- the line as it's drawn: lying at a spot with that much line out, hanging off the pole without. with what
	-- bit on its end, the sinker without
	getLine = function(position: Vector3?, length: number, fish: MeshKey?): ClientVFXType.Line
		return table.freeze({
			Limb = POLE.Limb,
			Offset = TIP,
			Position = position,
			Length = length,
			Thickness = 0.02,
			Color = Color3.fromRGB(248, 248, 248),
			EndSize = Vector3.one * 0.2,
			EndColor = Color3.fromRGB(159, 161, 172),
			EndMaterial = Enum.Material.Glass,
			EndMesh = fish or SINKER,
			EndMeshScale = END_MESH_SCALE,
			EndTurn = END_TURN,
		})
	end,
})
