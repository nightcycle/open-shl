--!strict
-- Services
-- Packages
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local ShotFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Shot")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
type ClientSignal<T> = AbilityType.ClientSignal<T>
type Layout<B> = AbilityType.Layout<B>
export type Bindings = {
	Ready: EventBinding, -- the first of a throw is in the hand, its clock starts
	Add: EventBinding, -- one more
	Load: StateBinding, -- from the first in the hand until they leave it
	Throw: EventBinding, -- all of them leave
	Launch: ClientSignal<ShotFactory.Launch>, -- once for each of them
	Hit: ClientSignal<ShotFactory.Hit>,
	Recover: EventBinding,
	Sheathe: EventBinding, -- the tool is put away with some in the hand
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: ShotFactory.Config, -- one of them in the air
	MAX_COUNT: number,
	getIfAdding: (count: number, age: number) -> boolean,
	getDirection: (direction: Vector3, index: number) -> Vector3,
	getProp: (index: number) -> ClientVFXType.Prop,
}
-- Constants
local ID = "ranged_kunai"
-- one that's out is out for longer than a throw takes: word of it comes in whatever the machine is up to by then
local STATE_IDS = table.freeze({ "Idle", "Loading", "Recovering" })
-- how many a throw is at most
local MAX_COUNT = 5
-- seconds from the first one during which a click is one more
local ADD_WINDOW = 0.7
-- seconds from the first one until a click throws them. a click in between does nothing
local THROW_DELAY = 1.45
-- seconds from a throw until the next first one
local RELOAD_DURATION = 1.5
-- how far the second + third of a throw are turned off the first, the fourth + fifth twice as far
local FAN_ANGLE = math.pi / 12
local SIZE = Vector3.new(0.2, 0.23, 1.34)
local COLOR = Color3.fromRGB(0, 143, 156)
local MESH_SCALE = Vector3.one * 1.1
-- how one sits in the hand: its point along the arm, the way the guns of the game are held, gripped this many
-- studs behind its middle
local GRIP_TURN = CFrame.Angles(math.pi / 2 - math.pi / 20, 0, 0)
local GRIP_DEPTH = 0.4
local SHOT: ShotFactory.Config = {
	ReleaseDelay = THROW_DELAY,
	Duration = THROW_DELAY + RELOAD_DURATION,
	Limb = "RightHand",
	Speed = 50,
	Lifetime = 4,
	Size = SIZE,
	Color = COLOR,
	Material = Enum.Material.SmoothPlastic,
	Mesh = "Kunai",
	MeshScale = MESH_SCALE,
	-- on its side, the way it left the hand
	Turn = CFrame.Angles(0, 0, math.pi / 2),
	LandSound = "Thunk",
}
table.freeze(SHOT)
-- Variables
-- References
-- Private Functions
-- how far the one of that place in a throw is turned off where the throw is aimed: none, then a step to either side
-- in turn
local function getAngle(index: number): number
	return math.ceil((index - 1) / 2) * FAN_ANGLE * (if index % 2 == 0 then -1 else 1)
end
-- Class
local equipped = AbilityCondition.equipped(ID)
local click = AbilityTrigger.during(AbilityTrigger.started(AbilityCondition.PRIMARY), AbilityTrigger.active(equipped))
-- a click with the tool out takes one in the hand. for a while every click is one more, up to five; later a click
-- throws them all at once, fanned out, each a shot of its own. the count is the client's to say + the server's to hold
-- it to, so every step is the client's call: how late one more still counts is held by a guard on each side, not by
-- the binding, since the clock of the server runs ahead + would shut the window early
local bindings: Bindings = {
	Ready = VFXBinding.event({ "Idle" }, click, { To = "Loading", Authority = "Client" }),
	Add = VFXBinding.event({ "Loading" }, click, { Authority = "Client" }),
	Load = VFXBinding.state({ "Loading" }, AbilityTrigger.always()),
	Throw = VFXBinding.event(
		{ "Loading" },
		AbilityTrigger.during(click, AbilityTrigger.active(AbilityCondition.elapsed(THROW_DELAY))),
		{ To = "Recovering", Authority = "Client" }
	),
	Launch = VFXBinding.signal(STATE_IDS, "Client", ShotFactory.Launch) :: ClientSignal<ShotFactory.Launch>,
	Hit = VFXBinding.signal(STATE_IDS, "Client", ShotFactory.Hit) :: ClientSignal<ShotFactory.Hit>,
	Recover = VFXBinding.event({ "Recovering" }, AbilityTrigger.after(RELOAD_DURATION), { To = "Idle" }),
	Sheathe = VFXBinding.event({ "Loading" }, AbilityTrigger.stopped(equipped), { To = "Idle" }),
}
local ability: Ability = table.freeze({
	Layout = VFXBinding.layout(ID, "Idle", true, bindings),
	Config = SHOT,
	MAX_COUNT = MAX_COUNT,
	-- whether a click that long after the first one is one more in a hand that holds that many
	getIfAdding = function(count: number, age: number): boolean
		return count < MAX_COUNT and age < ADD_WINDOW
	end,
	-- where the one of that place in a throw is headed: turned about the world's up, whatever the throw is aimed at
	getDirection = function(direction: Vector3, index: number): Vector3
		return (CFrame.Angles(0, getAngle(index), 0) * direction).Unit
	end,
	-- the one of that place as every machine shows it in the hand: fanned out the way they'll leave
	getProp = function(index: number): ClientVFXType.Prop
		return {
			Limb = SHOT.Limb,
			Size = SIZE,
			Offset = CFrame.new(0, 0, GRIP_DEPTH) * CFrame.Angles(0, -getAngle(index), 0) * GRIP_TURN,
			Color = COLOR,
			Material = Enum.Material.SmoothPlastic,
			Mesh = "Kunai",
			MeshScale = MESH_SCALE,
		}
	end,
})

return ability
