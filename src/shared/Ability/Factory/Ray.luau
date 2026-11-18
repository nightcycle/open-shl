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
}
-- how a ray is shown: a straight line from where it left to where it ended
export type Beam = {
	Thickness: number,
	Transparency: number?, -- solid without
	Lifetime: number, -- seconds until it's gone
	IsFading: boolean?, -- it thins out over its life, it's there + then it isn't without
	Material: Enum.Material?, -- it glows without
	Color: Color3, -- the one it has unless the character wears another
	IsSecondary: boolean?, -- it wears the second color of the character, the first without
}
-- more than one ray to a click
export type Burst = {
	Count: number,
	Interval: number, -- seconds between two of them
}
-- what both halves of a ray ability have to agree on
export type Config = {
	Duration: number, -- seconds from the click until the next one counts
	ReleaseDelay: number?, -- seconds from the click until the first ray leaves, at once without
	Burst: Burst?, -- one ray to a click without
	Limb: string, -- the name of the part of the avatar a ray leaves from
	Offset: Vector3?, -- of the spot on the limb it leaves from off the middle of it, in the space of the limb
	Range: number, -- studs a ray gets to
	Beams: { Beam }, -- every ray is shown as all of them at once
	Props: { Prop }, -- what's held for as long as the tool is out, bare hands hold nothing
	-- the color the character wears is worn by what's held as well, only by the beams without
	HasColoredProps: boolean?,
	FireSound: VFXAssetDefinition.SoundKey?, -- heard as a ray leaves
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
local STATE_IDS = table.freeze({ "Idle", "Firing" })
-- how far off 1 the length of a direction may be, a remote doesn't hand a vector on bit for bit
local DIRECTION_TOLERANCE = 0.01
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
	local isFire = Type.strictInterface({
		Id = Type.integer,
		Origin = AbilityType.FiniteVector3,
		Direction = isDirection,
		Distance = Type.numberConstrained(0, config.Range),
		Target = Type.optional(Type.instanceIsA("Model")),
	})
	local equipped = AbilityCondition.equipped(id)
	local bindings: Bindings = {
		Hold = VFXBinding.state(STATE_IDS, AbilityTrigger.active(equipped)),
		Cast = VFXBinding.event(
			{ "Idle" },
			AbilityTrigger.during(AbilityTrigger.started(AbilityCondition.PRIMARY), AbilityTrigger.active(equipped)),
			{ To = "Firing" }
		),
		Fire = VFXBinding.signal({ "Firing" }, "Client", isFire) :: ClientSignal<Fire>,
		Recover = VFXBinding.event({ "Firing" }, AbilityTrigger.after(config.Duration), { To = "Idle" }),
	}
	local out = table.clone(config)
	out.Beams = table.freeze(table.clone(config.Beams))
	out.Props = table.freeze(table.clone(config.Props))
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
		local worn = if beam.IsSecondary then secondaryColor else color
		table.insert(beams, {
			Origin = fire.Origin,
			Position = fire.Origin + fire.Direction * distance,
			Thickness = beam.Thickness,
			Color = worn or beam.Color,
			Material = beam.Material,
			Transparency = beam.Transparency,
			Lifetime = beam.Lifetime,
			IsFading = beam.IsFading,
			Key = `{ability.Layout.Id}/{fire.Id}/{index}`,
		})
	end
	return beams
end

-- one of the props as every machine shows it: in the color the character wears the ability in, if that's the
-- weapon's to wear
Module.getProp = function(config: Config, prop: Prop, color: Color3?): Prop
	local out = table.clone(prop)
	out.Color = if config.HasColoredProps and color then color else prop.Color
	return out
end

return Module
