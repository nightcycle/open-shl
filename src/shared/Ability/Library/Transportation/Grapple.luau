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
-- where the client let its hook fly, so it takes the same path on every machine
export type Launch = {
	Origin: Vector3,
	Direction: Vector3, -- of length 1
}
-- where the client saw its hook run into the world
export type Latch = {
	Position: Vector3,
}
export type Bindings = {
	Hold: StateBinding, -- the tool is out
	Fire: EventBinding, -- a click lets a hook fly, whatever became of the last one
	Refire: EventBinding, -- the same click with a hook in, which has to have held for a moment
	Launch: ClientSignal<Launch>,
	Flight: StateBinding, -- the hook is in the air, the rope behind it
	Latch: ClientSignal<Latch>,
	Lose: EventBinding, -- the rope ran out with nothing on the hook
	Tether: StateBinding, -- the hook is in, the rope runs to it
	Tighten: EventBinding, -- the rope goes taut
	Reel: StateBinding, -- the avatar is pulled to the hook
	Release: ClientSignal<nil>, -- the avatar got to the hook, or too far from it
	Sheathe: EventBinding,
}
-- what both halves of the grapple have to agree on
export type Config = {
	Limb: string, -- the name of the part of the avatar the hook leaves from + the rope is held by
	Speed: number, -- studs a second the hook flies at
	Range: number, -- studs from the avatar a hook holds at most
	Thickness: number, -- of the rope
	LatchSound: VFXAssetDefinition.SoundKey,
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
	getRope: (color: Color3, position: Vector3, origin: Vector3?) -> ClientVFXType.Rope,
}
-- Constants
local ID = "transportation_grapple"
local CONFIG: Config = table.freeze({
	Limb = "RightHand",
	Speed = 250,
	Range = 500,
	Thickness = 0.1,
	LatchSound = "Impact" :: VFXAssetDefinition.SoundKey,
})
-- seconds a hook that ran out of rope is still waited on: word of what it ran into last takes a while to get here
local LOSE_DELAY = 0.5
-- seconds from the hook going in until the rope pulls
local TIGHTEN_DELAY = 0.2
-- seconds the rope has to have pulled for before another click counts, so the click that's one too many doesn't
-- throw away a hook that only just went in
local REFIRE_DELAY = 0.3
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
local isLaunch = Type.strictInterface({
	Origin = AbilityType.FiniteVector3,
	Direction = isDirection,
})
local isLatch = Type.strictInterface({
	Position = AbilityType.FiniteVector3,
})
-- Variables
-- References
-- Private Functions
-- Class
local equipped = AbilityCondition.equipped(ID)
local click = AbilityTrigger.during(AbilityTrigger.started(AbilityCondition.PRIMARY), AbilityTrigger.active(equipped))
-- only ever raised while the rope pulls. it's taken with the hook just in as well: word of the hook going in + of
-- letting go of it can get to the server in one go, which would otherwise leave its rope up for good
local release: ClientSignal<nil> = VFXBinding.signal({ "Reeling", "Latched" }, "Client", Type.none, { To = "Idle" })
-- a click with the tool out lets a hook fly to where the player points. it goes in where it runs into the world +
-- the rope pulls the avatar there, until it has arrived, another hook is let fly or the tool is put away. the hook
-- is the client's to fly + the avatar its to move: it has the say on every step, the server hears of each + gets to
-- turn it down. a click always goes by way of the loaded state, so a hook that's still out is over with before the
-- next one leaves
local bindings: Bindings = {
	Hold = VFXBinding.state({ "Idle", "Loaded", "Flying", "Latched", "Reeling" }, AbilityTrigger.active(equipped)),
	Fire = VFXBinding.event({ "Idle", "Loaded", "Flying" }, click, { To = "Loaded", Authority = "Client" }),
	Refire = VFXBinding.event(
		{ "Reeling" },
		AbilityTrigger.during(click, AbilityTrigger.active(AbilityCondition.elapsed(REFIRE_DELAY))),
		{ To = "Loaded", Authority = "Client" }
	),
	Launch = VFXBinding.signal({ "Loaded" }, "Client", isLaunch, { To = "Flying" }) :: ClientSignal<Launch>,
	Flight = VFXBinding.state({ "Flying" }, AbilityTrigger.always()),
	Latch = VFXBinding.signal({ "Flying" }, "Client", isLatch, { To = "Latched" }) :: ClientSignal<Latch>,
	Lose = VFXBinding.event(
		{ "Flying" },
		AbilityTrigger.after(CONFIG.Range / CONFIG.Speed + LOSE_DELAY),
		{ To = "Idle" }
	),
	Tether = VFXBinding.state({ "Latched", "Reeling" }, AbilityTrigger.always()),
	Tighten = VFXBinding.event({ "Latched" }, AbilityTrigger.after(TIGHTEN_DELAY), { To = "Reeling" }),
	Reel = VFXBinding.state({ "Reeling" }, AbilityTrigger.always()),
	Release = release,
	Sheathe = VFXBinding.event(
		{ "Loaded", "Flying", "Latched", "Reeling" },
		AbilityTrigger.stopped(equipped),
		{ To = "Idle" }
	),
}
local ability: Ability = table.freeze({
	Layout = VFXBinding.layout(ID, "Idle", true, bindings),
	Config = CONFIG,
	-- the rope as every machine shows it: to where the hook is in, or on its way there from an origin
	getRope = function(color: Color3, position: Vector3, origin: Vector3?): ClientVFXType.Rope
		return {
			Limb = CONFIG.Limb,
			Position = position,
			Origin = origin,
			Speed = if origin then CONFIG.Speed else nil,
			Thickness = CONFIG.Thickness,
			Color = color,
		}
	end,
})

return ability
