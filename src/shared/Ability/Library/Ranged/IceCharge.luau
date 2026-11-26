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
	Cast: EventBinding,
	Charging: StateBinding, -- the button is down, the hand fills
	Release: EventBinding,
	Abort: EventBinding,
	Sheathe: EventBinding, -- the tool is put away with the button still down
	Launch: ClientSignal<ShotFactory.Launch>,
	Hit: ClientSignal<ShotFactory.Hit>,
	Land: ClientSignal<ShotFactory.Land>,
	Recover: EventBinding,
}
export type Ability = {
	Layout: Layout<Bindings>,
	-- the same ability the way the shot factory takes one: all it doesn't know of is the hand filling
	Shot: ShotFactory.Ability,
	FLAME: ClientVFXType.Flame,
	BALL: ClientVFXType.Prop,
	getFrost: (position: Vector3, seed: number) -> ClientVFXType.Frost,
}
-- Constants
local ID = "ranged_ice-charge"
local LIMB = "RightHand"
local BRIGHT_BLUE = BrickColor.new("Bright blue").Color
-- what a piece of the ice may be in
local COLORS = table.freeze({ BRIGHT_BLUE, BrickColor.new("Teal").Color, BrickColor.new("Deep blue").Color })
-- how many pieces the ice is made of, each bigger + slower to grow than the last
local CRYSTAL_COUNT = 7
-- seconds a piece takes to grow, for each place it's down the list
local GROW_INTERVAL = 1 / 3
-- studs a side of a piece is at least: the roll of the first few may come up none at all
local MIN_SIDE = 0.2
-- seconds from the landing until the ice is gone + lets go of whoever it holds
local HOLD_DURATION = 3
local SHOT: ShotFactory.Config = {
	-- how long the button has to be held for
	ReleaseDelay = 1.5,
	IsCharged = true,
	-- nothing to wait for once it's gone: the next one takes as long to fill the hand
	Duration = 1.55,
	Limb = LIMB,
	Speed = 200,
	Lifetime = 10,
	-- a ball under a small blue flame
	Size = Vector3.one,
	Color = BRIGHT_BLUE,
	SecondaryColor = BRIGHT_BLUE,
	FireSize = 2,
	HasLanding = true,
	-- the ice is heard forming where the ball ends
	LandSound = "IceForm",
}
table.freeze(SHOT)
local FLAME: ClientVFXType.Flame = table.freeze({
	Limb = LIMB,
	Size = 2,
	Heat = 9,
	Color = BRIGHT_BLUE,
})
local BALL: ClientVFXType.Prop = table.freeze({
	Limb = LIMB,
	Size = Vector3.one * 0.9,
	Offset = CFrame.identity,
	Color = BRIGHT_BLUE,
	Material = Enum.Material.Ice,
	Shape = Enum.PartType.Ball,
})
-- Variables
-- References
-- Private Functions
-- Class
-- held down the hand fills with ice, let go of once it's full a ball of it leaves: wherever that lands a cluster of
-- ice grows + whoever it reaches is hurt + held until it's gone. let go of any sooner nothing leaves + the hand
-- starts over
local shot = ShotFactory.newBindings(ID, SHOT)
local bindings: Bindings = {
	Cast = shot.Cast,
	Charging = VFXBinding.state({ "Casting" }, AbilityTrigger.always()),
	Release = shot.Release,
	Abort = shot.Abort :: EventBinding,
	Sheathe = VFXBinding.event({ "Casting" }, AbilityTrigger.stopped(AbilityCondition.equipped(ID)), { To = "Idle" }),
	Launch = shot.Launch,
	Hit = shot.Hit,
	Land = shot.Land :: ClientSignal<ShotFactory.Land>,
	Recover = shot.Recover,
}
local layout = VFXBinding.layout(ID, "Idle", true, bindings)
local ability: Ability = table.freeze({
	Layout = layout,
	Shot = table.freeze({
		-- a layout is one table of bindings, typed by whoever made it
		Layout = layout :: any,
		Config = SHOT,
	}),
	FLAME = FLAME,
	BALL = BALL,
	-- the ice of one landing as every machine shows it: rolled from what the server picked, so it's the same pieces
	-- for everybody. each is a block of whole studs turned any which way about the spot
	getFrost = function(position: Vector3, seed: number): ClientVFXType.Frost
		local random = Random.new(seed)
		local blocks: { ClientVFXType.FrostBlock } = {}
		for index = 1, CRYSTAL_COUNT do
			local lower = math.max(0, index - 3)
			local upper = index + 1
			local function roll(): number
				return math.max(random:NextInteger(lower, upper), MIN_SIDE)
			end
			local function turn(): number
				return random:NextNumber(0, 2 * math.pi)
			end
			blocks[index] = {
				Size = Vector3.new(roll(), roll(), roll()),
				Offset = CFrame.Angles(turn(), turn(), turn()),
				GrowDuration = index * GROW_INTERVAL,
				Color = COLORS[random:NextInteger(1, #COLORS)],
			}
		end
		return {
			CFrame = CFrame.new(position),
			Blocks = blocks,
			Lifetime = HOLD_DURATION,
		}
	end,
})

return ability
