--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Components
-- Hooks
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local AcrobaticsType = require("@game/ReplicatedStorage/Shared/Type/Acrobatics")
type SoundKey = VFXAssetDefinition.SoundKey
type AnimationKey = VFXAssetDefinition.AnimationKey
type MeshKey = VFXAssetDefinition.MeshKey
type ParticleKey = VFXAssetDefinition.ParticleKey

-- the props of every client effect. the ones a player's own machine may show to others are checked by the server
-- before they're passed on, so their validators are as tight as the effect allows
local Types = {}

local isFiniteVector3 = AbilityType.FiniteVector3
-- no side of a part an effect makes is longer than this
local MAX_SIZE = 16
local isSize = function(value: unknown): (boolean, string?)
	local success, msg = isFiniteVector3(value)
	if not success then
		return false, msg
	end
	local size = value :: Vector3
	if math.min(size.X, size.Y, size.Z) <= 0 or math.max(size.X, size.Y, size.Z) > MAX_SIZE then
		return false, `a size within {MAX_SIZE} studs expected, got {size}`
	end
	return true
end
-- a spot on a limb or on what it holds: nothing an effect hangs onto an avatar is further off than a part gets long
local isReach = function(value: unknown): (boolean, string?)
	local success, msg = isFiniteVector3(value)
	if not success then
		return false, msg
	end
	local reach = value :: Vector3
	if reach.Magnitude > MAX_SIZE then
		return false, `a spot within {MAX_SIZE} studs expected, got {reach}`
	end
	return true
end
-- studs a line through the world runs at most, nothing an ability lets go gets further
local MAX_LENGTH = 1000
-- a way something points: whatever its length, it has to point somewhere
local isDirection = function(value: unknown): (boolean, string?)
	local success, msg = isFiniteVector3(value)
	if not success then
		return false, msg
	end
	if (value :: Vector3).Magnitude <= 0 then
		return false, `a direction that points somewhere expected`
	end
	return true
end

-- held on the avatar until it's stopped
export type Animation = {
	Animation: AnimationKey,
	FadeTime: number?,
	Speed: number?,
}
Types.Animation = Type.strictInterface({
	Animation = VFXAssetDefinition.AnimationKey,
	FadeTime = Type.optional(Type.numberConstrained(0, 2)),
	Speed = Type.optional(Type.numberConstrained(0.1, 4)),
})

-- played once on the avatar from start to end
export type AnimationOnce = Animation
Types.AnimationOnce = Types.Animation

-- played once from the avatar
export type Sound = {
	Sound: SoundKey,
	Delay: number?, -- seconds until it's heard, at once without
}
Types.Sound = Type.strictInterface({
	Sound = VFXAssetDefinition.SoundKey,
	Delay = Type.optional(Type.numberConstrained(0, 5)),
})

-- looped from the avatar until it's stopped
export type SoundLoop = {
	Sound: SoundKey,
}
Types.SoundLoop = Type.strictInterface({
	Sound = VFXAssetDefinition.SoundKey,
})

-- a part held by a limb of the avatar
export type Prop = {
	Limb: string, -- the name of the part of the avatar it's welded to
	Size: Vector3,
	Offset: CFrame, -- of the limb from the prop
	Color: Color3,
	Material: Enum.Material?,
	Mesh: MeshKey?,
	MeshScale: Vector3?,
	MeshOffset: Vector3?, -- studs the mesh sits off the middle of the part
	Shape: Enum.PartType?, -- a block without
	-- where it comes out from + goes back to as it's put away, it's there + gone at once without
	SlideOffset: CFrame?,
	SlideDuration: number?, -- seconds it takes either way
	Delay: number?, -- seconds until it's there, the time a hand takes to reach for it
	Linger: number?, -- seconds it stays once it's put away, the time a hand takes to let go of it
}
Types.Prop = Type.strictInterface({
	Limb = Type.string,
	Size = isSize,
	Offset = Type.CFrame,
	Color = Type.Color3,
	Material = Type.optional(Type.enum(Enum.Material)),
	Mesh = Type.optional(VFXAssetDefinition.MeshKey),
	MeshScale = Type.optional(isSize),
	MeshOffset = Type.optional(isFiniteVector3),
	Shape = Type.optional(Type.enum(Enum.PartType)),
	SlideOffset = Type.optional(Type.CFrame),
	SlideDuration = Type.optional(Type.numberConstrained(0, 2)),
	Delay = Type.optional(Type.numberConstrained(0, 2)),
	Linger = Type.optional(Type.numberConstrained(0, 2)),
})

-- a ribbon a limb of the avatar leaves behind as it moves
export type Streak = {
	Limb: string, -- the name of the part of the avatar it's drawn out by
	-- the two ends of the edge it's drawn out from
	From: Vector3,
	To: Vector3,
	-- of the limb from what the two ends are measured on, the way a prop is held: the ribbon of a blade takes the
	-- offset of the blade. they're measured on the limb itself without
	Offset: CFrame?,
	Lifetime: number, -- seconds until a stretch of it is gone
	Transparency: number, -- of where it's drawn out, it thins out to nothing from there
	Color: Color3,
	Delay: number?, -- seconds until it's there, the time a hand takes to reach for what leaves it
	Linger: number?, -- seconds it stays once it's stopped, the time a hand takes to let go of what leaves it
}
Types.Streak = Type.strictInterface({
	Limb = Type.string,
	From = isReach,
	To = isReach,
	Offset = Type.optional(Type.CFrame),
	Lifetime = Type.numberConstrained(0.01, 2),
	Transparency = Type.numberConstrained(0, 1),
	Color = Type.Color3,
	Delay = Type.optional(Type.numberConstrained(0, 2)),
	Linger = Type.optional(Type.numberConstrained(0, 2)),
})

-- two ribbons behind every part of the body of the avatar: one as tall as the part, one as wide
export type Wake = {
	Color: Color3?, -- of the tall ones, the color of each part itself without
	SecondaryColor: Color3?, -- of the wide ones
	Lifetime: number, -- seconds until a stretch of one is gone
	Depth: number, -- studs behind the middle of a part its ribbons are drawn out from
}
Types.Wake = Type.strictInterface({
	Color = Type.optional(Type.Color3),
	SecondaryColor = Type.optional(Type.Color3),
	Lifetime = Type.numberConstrained(0.01, 2),
	Depth = Type.numberConstrained(0, MAX_SIZE),
})

-- a glowing shot on its way through the world
export type Bolt = {
	Origin: Vector3,
	Direction: Vector3,
	Speed: number,
	Lifetime: number,
	Size: Vector3,
	Color: Color3,
	FireSize: number?, -- of the flame it trails, none without
	FireHeat: number?, -- how fast its flame rises, as fast as one that trails a shot without
	SecondaryColor: Color3?, -- of the sparks of its flame, the color of the rest of it without
	HasSparkles: boolean?, -- it trails sparkles
	Particles: { ParticleKey }?, -- what it gives off on its way
	Material: Enum.Material?, -- it glows without
	Mesh: MeshKey?,
	MeshScale: Vector3?,
	-- how it's turned off the way it flies. without: a flame trails behind it, anything else points ahead
	Turn: CFrame?,
	Gravity: number?, -- studs a second it picks up downwards every second, it flies straight without
	IsSticking: boolean?, -- it's left where it ran into something for as long as it had left to fly
	LandSound: SoundKey?, -- heard from where it ran into something, one that runs into nothing is never heard
	OnHit: ((result: RaycastResult) -> ())?, -- only ever set by the machine that shot it
}
Types.Bolt = Type.strictInterface({
	Origin = isFiniteVector3,
	Direction = isFiniteVector3,
	Speed = Type.numberPositive,
	Lifetime = Type.numberPositive,
	Size = isSize,
	Color = Type.Color3,
	FireSize = Type.optional(Type.numberConstrained(0, 30)),
	FireHeat = Type.optional(Type.numberConstrained(-25, 25)),
	SecondaryColor = Type.optional(Type.Color3),
	HasSparkles = Type.optional(Type.boolean),
	Particles = Type.optional(Type.array(VFXAssetDefinition.ParticleKey)),
	Material = Type.optional(Type.enum(Enum.Material)),
	Mesh = Type.optional(VFXAssetDefinition.MeshKey),
	MeshScale = Type.optional(isSize),
	Turn = Type.optional(Type.CFrame),
	Gravity = Type.optional(Type.numberMin(0)),
	IsSticking = Type.optional(Type.boolean),
	LandSound = Type.optional(VFXAssetDefinition.SoundKey),
	OnHit = Type.optional(Type.callback),
})

-- holds the avatar in the air, turned to where its player points
export type Hover = {
	Height: number, -- studs it rises as it takes off
}
Types.Hover = Type.strictInterface({
	Height = Type.number,
})

-- pulls a hovering avatar to where its player points
export type Thrust = {
	Power: number, -- studs ahead of the avatar it's pulled to
}
Types.Thrust = Type.strictInterface({
	Power = Type.numberPositive,
})

-- the "not enough energy" warning of the hud
export type EnergyWarning = {}
Types.EnergyWarning = Type.strictInterface({})

-- makes the avatar harder to see
export type Cloak = {
	Transparency: number, -- 1 is gone altogether
	FadeDuration: number?, -- seconds the avatar takes to go + to come back, it's there + gone at once without
	IsUnlit: boolean?, -- the lights the avatar carries go out for as long as it's on, they stay lit without
}
Types.Cloak = Type.strictInterface({
	Transparency = Type.numberConstrained(0, 1),
	FadeDuration = Type.optional(Type.numberConstrained(0, 5)),
	IsUnlit = Type.optional(Type.boolean),
})

-- every part of the avatar in one material + color
export type Coat = {
	Material: Enum.Material,
	Color: Color3,
}
Types.Coat = Type.strictInterface({
	Material = Type.enum(Enum.Material),
	Color = Type.Color3,
})

-- how the screen of whoever shows it takes the world in
export type ScreenFilter = {
	Brightness: number,
	Contrast: number,
	Saturation: number,
	Blur: number,
}
Types.ScreenFilter = Type.strictInterface({
	Brightness = Type.numberConstrained(-1, 1),
	Contrast = Type.numberConstrained(-1, 1),
	Saturation = Type.numberConstrained(-1, 1),
	Blur = Type.numberConstrained(0, 56),
})

-- how wide the camera of whoever shows it takes the world in
export type FieldOfView = {
	FieldOfView: number, -- degrees
	Duration: number, -- seconds the camera takes to get there + to get back
	IsMoving: boolean?, -- only for as long as the avatar is on the move, all the while without
}
Types.FieldOfView = Type.strictInterface({
	FieldOfView = Type.numberConstrained(1, 120),
	Duration = Type.numberConstrained(0, 5),
	IsMoving = Type.optional(Type.boolean),
})

-- the camera of whoever shows it follows somebody else, picked with the buttons it comes with
export type Spectate = {
	Targets: { Model }?, -- who there is to watch, the avatar of every other player without
}
Types.Spectate = Type.strictInterface({
	Targets = Type.optional(Type.array(Type.instanceIsA("Model"))),
})

-- holds the avatar where it stands: it neither walks nor jumps
export type Root = {}
Types.Root = Type.strictInterface({})

-- puts the avatar somewhere else at once, upright + facing the way the world does
export type Warp = {
	Position: Vector3, -- where the middle of it ends up
}
Types.Warp = Type.strictInterface({
	Position = isFiniteVector3,
})

-- has the avatar walk at another pace
export type WalkSpeed = {
	WalkSpeed: number, -- studs a second
}
Types.WalkSpeed = Type.strictInterface({
	WalkSpeed = Type.numberConstrained(0, 200),
})

-- a part of the world nobody stands on carries the avatar for as long as it keeps moving
export type Skim = {
	Part: BasePart,
}
Types.Skim = Type.strictInterface({
	Part = Type.instanceIsA("BasePart"),
})

-- carries the avatar straight up, where it goes sideways is left to its player
export type Lift = {
	Speed: number, -- studs a second
	Clearance: number, -- studs ahead of the avatar something has to be within for it to count as up against it
}
Types.Lift = Type.strictInterface({
	Speed = Type.numberConstrained(0, 200),
	Clearance = Type.numberConstrained(0, 50),
})

-- pulls the avatar to a spot in a straight line, turned the way it was as the pull began
export type Reel = {
	Position: Vector3,
	Speed: number, -- studs a second
}
Types.Reel = Type.strictInterface({
	Position = isFiniteVector3,
	Speed = Type.numberConstrained(0, 200),
})

-- a line from a limb of the avatar to a spot of the world
export type Rope = {
	Limb: string, -- the name of the part of the avatar that holds it
	Position: Vector3, -- where its far end is, or is headed
	Origin: Vector3?, -- where its far end sets out from, it's at the position right away without
	Speed: number?, -- studs a second its far end flies at
	Thickness: number,
	Color: Color3,
}
Types.Rope = Type.strictInterface({
	Limb = Type.string,
	Position = isFiniteVector3,
	Origin = Type.optional(isFiniteVector3),
	Speed = Type.optional(Type.numberPositive),
	Thickness = Type.numberConstrained(0.05, 4),
	Color = Type.Color3,
})

-- a limb of the avatar gives off particles
export type Plume = {
	Limb: string, -- the name of the part of the avatar they come from
	Particle: VFXAssetDefinition.ParticleKey,
}
Types.Plume = Type.strictInterface({
	Limb = Type.string,
	Particle = VFXAssetDefinition.ParticleKey,
})

-- a limb of the avatar gives off smoke
export type Smoke = {
	Limb: string,
	Size: number,
	RiseVelocity: number, -- studs a second it goes up at, below 0 it sinks
	Opacity: number,
	Color: Color3,
}
Types.Smoke = Type.strictInterface({
	Limb = Type.string,
	Size = Type.numberConstrained(0.1, 100),
	RiseVelocity = Type.numberConstrained(-25, 25),
	Opacity = Type.numberConstrained(0, 1),
	Color = Type.Color3,
})

-- a limb of the avatar is on fire
export type Flame = {
	Limb: string,
	Size: number,
	Heat: number, -- how fast the flames rise, at 0 they stay where they are
	Color: Color3,
	SecondaryColor: Color3?, -- of its sparks, the color of the rest of it without
}
Types.Flame = Type.strictInterface({
	Limb = Type.string,
	Size = Type.numberConstrained(2, 30),
	Heat = Type.numberConstrained(-25, 25),
	Color = Type.Color3,
	SecondaryColor = Type.optional(Type.Color3),
})

-- a flat picture in the world that grows + fades until it's gone
export type Ripple = {
	Decal: VFXAssetDefinition.DecalKey, -- what's on both faces of it
	CFrame: CFrame, -- where it starts out + how it lies
	Size: Vector3,
	EndSize: Vector3, -- what it has grown to by the time it's gone
	Lifetime: number, -- seconds until it has faded
	Velocity: Vector3?, -- studs a second it travels at, it stays where it is without
}
Types.Ripple = Type.strictInterface({
	Decal = VFXAssetDefinition.DecalKey,
	CFrame = Type.CFrame,
	Size = isSize,
	EndSize = isFiniteVector3,
	Lifetime = Type.numberConstrained(0.05, 10),
	Velocity = Type.optional(isFiniteVector3),
})

-- how a line through the world is broken up: every viewer rolls the turns of their own
export type BeamJitter = {
	Step: number, -- studs along the way from one turn to the next
	Spread: number, -- whole studs a turn is off the straight line at most, either way on every axis of the world
}
Types.BeamJitter = Type.strictInterface({
	Step = Type.numberConstrained(1, 100),
	Spread = Type.numberConstrained(1, MAX_SIZE),
})

-- a straight line between two spots of the world that's there for a moment
export type Beam = {
	Origin: Vector3,
	Position: Vector3, -- where its far end is
	Thickness: number,
	Color: Color3,
	Material: Enum.Material?, -- it glows without
	Transparency: number?, -- solid without
	Lifetime: number, -- seconds until it's gone
	IsFading: boolean?, -- it thins out over its life, it's there + then it isn't without
	Jitter: BeamJitter?, -- it's drawn as a jagged line that ends where it would have, straight without
	-- one that's drawn under the key of another of its character takes the place of that one + is gone when it would
	-- have been: how a beam the server found to end somewhere else is put right
	Key: string?,
}
local isBeam = Type.strictInterface({
	Origin = isFiniteVector3,
	Position = isFiniteVector3,
	Thickness = Type.numberConstrained(0.05, 4),
	Color = Type.Color3,
	Material = Type.optional(Type.enum(Enum.Material)),
	Transparency = Type.optional(Type.numberConstrained(0, 1)),
	Lifetime = Type.numberConstrained(0.05, 5),
	IsFading = Type.optional(Type.boolean),
	Jitter = Type.optional(Types.BeamJitter),
	Key = Type.optional(Type.string),
})
Types.Beam = function(value: unknown): (boolean, string?)
	local success, msg = isBeam(value)
	if not success then
		return false, msg
	end
	local beam = value :: Beam
	local length = (beam.Position - beam.Origin).Magnitude
	if length > MAX_LENGTH then
		return false, `a beam within {MAX_LENGTH} studs expected, got one of {length}`
	end
	return true
end

-- a spot on a limb of the avatar gives off particles for a moment
export type Flare = {
	Limb: string, -- the name of the part of the avatar they come from
	Offset: Vector3?, -- of the spot off the middle of the limb, in the space of the limb
	Particle: ParticleKey,
	Duration: number, -- seconds it gives them off for, what's in the air by then lives out its life
}
Types.Flare = Type.strictInterface({
	Limb = Type.string,
	Offset = Type.optional(isReach),
	Particle = VFXAssetDefinition.ParticleKey,
	Duration = Type.numberConstrained(0.05, 2),
})

-- what's left sticking in whatever is at a spot of the world: it goes where that goes until its time is up
export type Shaft = {
	Position: Vector3, -- where the middle of it is
	Direction: Vector3, -- the way it points, the way whatever left it there flew
	Size: Vector3,
	Color: Color3,
	Mesh: MeshKey?,
	MeshScale: Vector3?,
	MeshOffset: Vector3?, -- studs the mesh sits off the middle of the part
	Lifetime: number, -- seconds until it's gone
}
Types.Shaft = Type.strictInterface({
	Position = isFiniteVector3,
	Direction = isDirection,
	Size = isSize,
	Color = Type.Color3,
	Mesh = Type.optional(VFXAssetDefinition.MeshKey),
	MeshScale = Type.optional(isSize),
	MeshOffset = Type.optional(isFiniteVector3),
	Lifetime = Type.numberConstrained(0.05, 30),
})

-- limbs of the avatar let bolts fly for as long as it's on, a round of one each at a time
export type Spray = {
	Limbs: { string }, -- the names of the parts of the avatar they leave from
	Interval: number, -- seconds between two rounds
	Turn: CFrame, -- how the way a bolt leaves is turned off the way its limb faces
	Speed: number,
	Lifetime: number,
	Gravity: number?, -- studs a second they pick up downwards every second, they fly straight without
	Size: Vector3,
	Color: Color3,
	Material: Enum.Material?, -- they glow without
	Mesh: MeshKey?,
	MeshScale: Vector3?,
	OnHit: ((result: RaycastResult) -> ())?, -- only ever set by the machine of the avatar
}
Types.Spray = Type.strictInterface({
	Limbs = Type.array(Type.string),
	Interval = Type.numberConstrained(0.02, 10),
	Turn = Type.CFrame,
	Speed = Type.numberPositive,
	Lifetime = Type.numberPositive,
	Gravity = Type.optional(Type.numberMin(0)),
	Size = isSize,
	Color = Type.Color3,
	Material = Type.optional(Type.enum(Enum.Material)),
	Mesh = Type.optional(VFXAssetDefinition.MeshKey),
	MeshScale = Type.optional(isSize),
	OnHit = Type.optional(Type.callback),
})

-- throws the avatar + turns it over on its way a step at a time, then lets go of it
export type Tumble = {
	Up: number, -- studs a second it's thrown straight up at
	Forward: number, -- studs a second along where it looks as it starts, below 0 it's thrown backwards
	Phases: { AcrobaticsType.Phase }, -- what turns it, in order
	IsTurned: boolean, -- false: it's only thrown, for as long as its turn would have taken
	OnEnded: (() -> ())?, -- it ran out by itself. only ever set by the machine of the avatar
}
Types.Tumble = Type.strictInterface({
	Up = Type.numberConstrained(0, 200),
	Forward = Type.numberConstrained(-200, 200),
	Phases = Type.array(AcrobaticsType.Phase),
	IsTurned = Type.boolean,
	OnEnded = Type.optional(Type.callback),
})

return Types
