--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
type ServerSignal<T> = AbilityType.ServerSignal<T>
type Layout<B> = AbilityType.Layout<B>
export type Bindings = {
	TakeOff: EventBinding,
	Aloft: StateBinding, -- up in the air, pulled or not
	Idle: StateBinding, -- nothing pulls, the avatar stays where it was last headed
	Thrust: StateBinding, -- pulled to where the player points
	Exhaust: ServerSignal<nil>, -- the energy ran out, which only the server knows
	Land: EventBinding,
}
-- what both halves of the flight have to agree on
export type Config = {
	Height: number, -- studs the avatar rises as it takes off
	Power: number, -- studs ahead of itself the avatar is pulled to
	Sound: VFXAssetDefinition.SoundKey?, -- the wind around whoever is up, it's quiet up there without
	FieldOfView: ClientVFXType.FieldOfView?, -- how the view of whoever is pulled along widens, it stays as it is without
	Wake: ClientVFXType.Wake?, -- what whoever is up leaves behind, in the colors of the character. nothing without
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
local ID = "transportation_flight"
-- seconds the avatar gets to ease into + out of how it holds itself in the air
local EASE_DURATION = 0.1
local CONFIG: Config = {
	Height = 10,
	Power = 35,
	Sound = "Wind",
}
-- Variables
-- References
-- Private Functions
-- Class
local equipped = AbilityCondition.equipped(ID)
-- the tool stays in the hand, it has to be put away + taken out for another go
local exhaust: ServerSignal<nil> = VFXBinding.signal(
	{ "Flying" },
	"Server",
	Type.none,
	{ To = "Grounded", Duration = EASE_DURATION }
)
-- the avatar is up for as long as the tool is out + there's energy to stay there, holding the primary input pulls
-- it along
local bindings: Bindings = {
	TakeOff = VFXBinding.event(
		{ "Grounded" },
		AbilityTrigger.started(equipped),
		{ To = "Flying", Duration = EASE_DURATION }
	),
	Aloft = VFXBinding.state({ "Flying" }, AbilityTrigger.always()),
	Idle = VFXBinding.state({ "Flying" }, AbilityTrigger.inactive(AbilityCondition.PRIMARY)),
	Thrust = VFXBinding.state({ "Flying" }, AbilityTrigger.active(AbilityCondition.PRIMARY)),
	Exhaust = exhaust,
	Land = VFXBinding.event(
		{ "Flying" },
		AbilityTrigger.stopped(equipped),
		{ To = "Grounded", Duration = EASE_DURATION }
	),
}
-- being up is the same in every game, how hard it pulls + what's seen + heard of it isn't
local ability: Ability = table.freeze({
	Layout = VFXBinding.layout(ID, "Grounded", true, bindings),
	Config = GameDefinition.tune(table.freeze(CONFIG), {
		shl3 = FreezeUtil.delta(CONFIG, function(config: Config): Config
			config.Height = 10
			-- nearly twice the pull, in silence
			config.Power = 65
			config.Sound = nil
			config.FieldOfView = { FieldOfView = 100, Duration = 0.5 }
			config.Wake = { Lifetime = 0.2, Depth = 0.5 }
			return config
		end),
		shl1 = FreezeUtil.delta(CONFIG, function(config: Config): Config
			config.Height = 10
			-- a far shorter pull, in silence
			config.Power = 10
			config.Sound = nil
			return config
		end),
	}),
})

return ability
