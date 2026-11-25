--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
type ClientSignal<T> = AbilityType.ClientSignal<T>
type ServerSignal<T> = AbilityType.ServerSignal<T>
type Layout<B> = AbilityType.Layout<B>
type Prop = ClientVFXType.Prop
-- where the client let a ray go + what it found in its way
export type Fire = {
	Id: number, -- the client's own count of its rays, the beam of one is told by it
	Origin: Vector3,
	Direction: Vector3, -- of length 1
	Distance: number, -- studs until it ran into something, as far as it gets if it didn't
	Target: Model?, -- the character it ran into, if it's one
}
export type Bindings = {
	Hold: StateBinding, -- the tool is out
	Cast: EventBinding, -- the click
	Fire: ClientSignal<Fire>, -- a ray leaves
	Recover: EventBinding,
	-- only an ability that's held has the two
	Repeat: EventBinding?, -- the cast that follows one, the button still down
	Held: StateBinding?, -- the button is down with the tool out + nothing is being filled
	-- only an ability with a clip has the four
	ReloadKey: EventBinding?, -- the key that asks for it to be filled
	Reload: ClientSignal<nil>?, -- it's being filled: the key with one that isn't full, a click on an empty one
	Refill: StateBinding?, -- for as long as that takes
	Reloaded: EventBinding?, -- it's full
	-- only an ability that can be held up has the two
	Stall: ServerSignal<nil>?, -- a ray of the cast set something off that holds its caster up
	Resume: EventBinding?,
}
-- how a ray is shown: a line from where it left to where it ended
export type Beam = {
	Thickness: number,
	Transparency: number?, -- solid without
	Lifetime: number, -- seconds until it's gone
	IsFading: boolean?, -- it thins out over its life, it's there + then it isn't without
	Material: Enum.Material?, -- it glows without
	Color: Color3, -- the one it has unless the character wears another
	IsSecondary: boolean?, -- it wears the second color of the character, the first without
	IsPlain: boolean?, -- it keeps its own color whatever the character wears
	Jitter: ClientVFXType.BeamJitter?, -- it's drawn as a jagged line, straight without
}
-- more than one ray to a click
export type Burst = {
	Count: number,
	Interval: number, -- seconds between two of them
}
-- what the spot a ray leaves from gives off as it leaves
export type Flare = {
	Particle: VFXAssetDefinition.ParticleKey,
	Duration: number, -- seconds it gives them off for
}
-- what's left sticking where a ray ended, a ray that ran into nothing leaves none
export type Shaft = {
	Size: Vector3,
	Mesh: VFXAssetDefinition.MeshKey?,
	MeshScale: Vector3?,
	MeshOffset: Vector3?,
	Color: Color3, -- the one it has unless the character wears another
	IsSecondary: boolean?, -- it wears the second color of the character, the first without
	Lifetime: number, -- seconds until it's gone
}
-- casts until it has to be filled again
export type Clip = {
	Size: number,
	ReloadDuration: number, -- seconds filling it takes, no cast meanwhile
}
-- what both halves of a ray ability have to agree on
export type Config = {
	Duration: number, -- seconds from the click until the next one counts
	ReleaseDelay: number?, -- seconds from the click until the first ray leaves, at once without
	Burst: Burst?, -- one ray to a click without
	Limb: string, -- the name of the part of the avatar a ray leaves from
	Offset: Vector3?, -- of the spot on the limb it leaves from off the middle of it, in the space of the limb
	Offsets: { Vector3 }?, -- the rays of a cast leave from these in turn, all from the offset without
	Range: number, -- studs a ray gets to
	-- how far off what's pointed at a ray may go either way on every axis, as a share of how far off that is. dead on
	-- without
	Spread: number?,
	Beams: { Beam }, -- every ray is shown as all of them at once
	Props: { Prop }, -- what's held for as long as the tool is out, bare hands hold nothing
	-- the color the character wears is worn by what's held as well, only by the beams without
	HasColoredProps: boolean?,
	Plumes: { ClientVFXType.Plume }?, -- what limbs give off for as long as the tool is out, nothing without
	FireSound: VFXAssetDefinition.SoundKey?, -- heard as a ray leaves
	Flare: Flare?,
	Shaft: Shaft?,
	-- a cast follows the last for as long as the button is down, a click is one cast without
	IsHeld: boolean?,
	HeldSound: VFXAssetDefinition.SoundKey?, -- heard for as long as the button of one that's held is down with the tool out
	Clip: Clip?, -- it never runs dry without
	-- a ray takes nothing off whoever it reaches: what it sets off is the ability's own to say
	IsHarmless: boolean?,
	Heal: number?, -- whoever a ray reaches gets this much health back + loses none
	-- seconds more until the next click counts once the server says a ray of the cast set something off that holds
	-- its caster up. the wait is the same whatever a ray did without
	Stall: number?,
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
-- how far off 1 the length of a direction may be, a remote doesn't hand a vector on bit for bit
local DIRECTION_TOLERANCE = 0.01
-- what a clip is filled with on every device
local RELOAD = AbilityCondition.input(Enum.KeyCode.R, Enum.KeyCode.ButtonX)
local isDirection = function(value: unknown): (boolean, string?)
	local success, msg = AbilityType.FiniteVector3(value)
	if not success then
		return false, msg
	end
	local length = (value :: Vector3).Magnitude
	if math.abs(length - 1) > DIRECTION_TOLERANCE then
		return false, `a direction of length 1 expected, got one of {length}`
	end
	return true
end
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- how many rays a click lets go
Module.getCount = function(config: Config): number
	return if config.Burst then config.Burst.Count else 1
end

-- seconds into a cast its ray of that number leaves, counted from 1
Module.getReleaseDelay = function(config: Config, index: number): number
	return (config.ReleaseDelay or 0) + (index - 1) * (if config.Burst then config.Burst.Interval else 0)
end

-- the spot on the limb the ray of that number of a cast leaves from, the middle of the limb without one
Module.getOffset = function(config: Config, index: number): Vector3?
	local offsets = config.Offsets
	return if offsets then offsets[(index - 1) % #offsets + 1] else config.Offset
end

-- what a cast begins with: the click + what follows it for one that's held. whatever a half does at a cast it does at
-- each of them
Module.getCasts = function(ability: Ability): { EventBinding }
	local bindings = ability.Layout.Bindings
	local casts = { bindings.Cast }
	if bindings.Repeat then
		table.insert(casts, bindings.Repeat)
	end
	return casts
end

-- the bindings of an ability that lets go of something that's there at once: a click with the tool out lets a ray go
-- (or a few in a row) + whoever is first in its way is hit there + then. there's nothing in flight, so where it left
-- from + what it ran into are one word of the client. the wait until the next click runs on with the tool put away
Module.new = function(id: string, config: Config): Ability
	local count = Module.getCount(config)
	assert(count >= 1 and count % 1 == 0, `a cast of "{id}" lets go of a whole number of rays, not {count}`)
	assert(config.Range > 0, `a ray of "{id}" gets nowhere`)
	assert(
		Module.getReleaseDelay(config, count) < config.Duration,
		`a cast of "{id}" is over before the last of its rays is let go`
	)
	assert(not config.Offsets or #config.Offsets > 0, `the rays of "{id}" have no spot to leave from`)
	assert(not config.HeldSound or config.IsHeld, `"{id}" is heard while it's held + isn't held`)
	local isFire = Type.strictInterface({
		Id = Type.integer,
		Origin = AbilityType.FiniteVector3,
		Direction = isDirection,
		Distance = Type.numberConstrained(0, config.Range),
		Target = Type.optional(Type.instanceIsA("Model")),
	})
	local equipped = AbilityCondition.equipped(id)
	local clip = config.Clip
	local stall = config.Stall
	-- the tool is out whatever the machine is up to
	local stateIds = { "Idle", "Firing" }
	if clip then
		table.insert(stateIds, "Reloading")
	end
	if stall then
		table.insert(stateIds, "Stalled")
	end
	-- the cast of one that's held can be over on the server before word of its rays is in: it's that far ahead
	local fireStateIds = if config.IsHeld then { "Idle", "Firing" } else { "Firing" }
	local bindings: Bindings = {
		Hold = VFXBinding.state(stateIds, AbilityTrigger.active(equipped)),
		Cast = VFXBinding.event(
			{ "Idle" },
			AbilityTrigger.during(AbilityTrigger.started(AbilityCondition.PRIMARY), AbilityTrigger.active(equipped)),
			{ To = "Firing" }
		),
		Fire = VFXBinding.signal(fireStateIds, "Client", isFire) :: ClientSignal<Fire>,
		Recover = VFXBinding.event({ "Firing" }, AbilityTrigger.after(config.Duration), { To = "Idle" }),
	}
	if config.IsHeld then
		local held =
			AbilityTrigger.all(AbilityTrigger.active(AbilityCondition.PRIMARY), AbilityTrigger.active(equipped))
		-- the client has the say: the server is ahead of the wait, left to itself it would cast again before the last
		-- cast of its client is over
		bindings.Repeat = VFXBinding.event(
			{ "Idle" },
			AbilityTrigger.during(AbilityTrigger.entered(), held),
			{ To = "Firing", Authority = "Client" }
		)
		bindings.Held = VFXBinding.state({ "Idle", "Firing" }, held)
	end
	if clip then
		assert(clip.Size >= 1 and clip.Size % 1 == 0, `the clip of "{id}" holds a whole number of casts`)
		assert(clip.ReloadDuration >= config.Duration, `the clip of "{id}" is full before a cast is over`)
		bindings.ReloadKey = VFXBinding.event(
			{ "Idle", "Firing" },
			AbilityTrigger.during(AbilityTrigger.started(RELOAD), AbilityTrigger.active(equipped))
		)
		bindings.Reload = VFXBinding.signal({ "Idle", "Firing" }, "Client", Type.none, { To = "Reloading" })
		bindings.Refill = VFXBinding.state({ "Reloading" }, AbilityTrigger.always())
		bindings.Reloaded = VFXBinding.event(
			{ "Reloading" },
			AbilityTrigger.after(clip.ReloadDuration),
			{ To = "Idle" }
		)
	end
	if stall then
		assert(stall > 0, `what holds "{id}" up takes no time`)
		bindings.Stall = VFXBinding.signal(fireStateIds, "Server", Type.none, { To = "Stalled" })
		bindings.Resume = VFXBinding.event(
			{ "Stalled" },
			AbilityTrigger.after(config.Duration + stall),
			{ To = "Idle" }
		)
	end
	local out = table.clone(config)
	out.Beams = table.freeze(table.clone(config.Beams))
	out.Props = table.freeze(table.clone(config.Props))
	if config.Offsets then
		out.Offsets = table.freeze(table.clone(config.Offsets))
	end
	if config.Plumes then
		out.Plumes = table.freeze(table.clone(config.Plumes))
	end
	return table.freeze({
		Layout = VFXBinding.layout(id, "Idle", true, bindings),
		Config = table.freeze(out),
	})
end

-- a ray as every machine shows it: from where its client let it go to however far it got, in the colors its character
-- wears. each beam goes by a key of its own, so the same ray shown again takes the place of what was shown of it
Module.getBeams = function(
	ability: Ability,
	fire: Fire,
	distance: number,
	color: Color3?,
	secondaryColor: Color3?
): { ClientVFXType.Beam }
	local beams: { ClientVFXType.Beam } = {}
	for index, beam in ability.Config.Beams do
		local worn = if beam.IsPlain then nil elseif beam.IsSecondary then secondaryColor else color
		table.insert(beams, {
			Origin = fire.Origin,
			Position = fire.Origin + fire.Direction * distance,
			Thickness = beam.Thickness,
			Color = worn or beam.Color,
			Material = beam.Material,
			Transparency = beam.Transparency,
			Lifetime = beam.Lifetime,
			IsFading = beam.IsFading,
			Jitter = beam.Jitter,
			Key = `{ability.Layout.Id}/{fire.Id}/{index}`,
		})
	end
	return beams
end

-- what a ray leaves sticking where it ended as every machine shows it, pointing the way it flew. nil for an ability
-- that leaves nothing + for a ray that ran into nothing
Module.getShaft = function(
	ability: Ability,
	fire: Fire,
	distance: number,
	color: Color3?,
	secondaryColor: Color3?
): ClientVFXType.Shaft?
	local shaft = ability.Config.Shaft
	if not shaft or distance >= ability.Config.Range then
		return nil
	end
	local worn = if shaft.IsSecondary then secondaryColor else color
	return {
		Position = fire.Origin + fire.Direction * distance,
		Direction = fire.Direction,
		Size = shaft.Size,
		Color = worn or shaft.Color,
		Mesh = shaft.Mesh,
		MeshScale = shaft.MeshScale,
		MeshOffset = shaft.MeshOffset,
		Lifetime = shaft.Lifetime,
	}
end

-- what the spot the ray of that number of a cast leaves from gives off as every machine shows it, nil for an ability
-- that gives nothing off
Module.getFlare = function(config: Config, index: number): ClientVFXType.Flare?
	local flare = config.Flare
	if not flare then
		return nil
	end
	return {
		Limb = config.Limb,
		Offset = Module.getOffset(config, index),
		Particle = flare.Particle,
		Duration = flare.Duration,
	}
end

-- one of the props as every machine shows it: in the color the character wears the ability in, if that's the
-- weapon's to wear
Module.getProp = function(config: Config, prop: Prop, color: Color3?): Prop
	local out = table.clone(prop)
	out.Color = if config.HasColoredProps and color then color else prop.Color
	return out
end

return Module
