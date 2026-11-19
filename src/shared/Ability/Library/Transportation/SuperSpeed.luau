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
	Start: EventBinding,
	Sprint: StateBinding, -- the avatar runs at full pace
	Skim: StateBinding, -- water carries whoever keeps moving, out of breath or not
	Exhaust: ServerSignal<nil>, -- the energy ran out, which only the server knows
	Rest: StateBinding, -- out of breath with the tool still out
	Recover: ServerSignal<nil>, -- there's energy to run on again
	Stop: EventBinding,
}
-- what both halves of the super speed have to agree on
export type Config = {
	WalkSpeed: number, -- studs a second the avatar runs at
	Sound: VFXAssetDefinition.SoundKey?, -- the wind around whoever runs, a run is quiet without
	FieldOfView: ClientVFXType.FieldOfView?, -- how the view of whoever runs widens, it stays as it is without
	Wake: ClientVFXType.Wake?, -- what whoever runs leaves behind, in the colors of the character. nothing without
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
local ID = "transportation_super-speed"
local CONFIG: Config = {
	WalkSpeed = 80,
	Sound = "Wind",
}
-- Variables
-- References
-- Private Functions
-- Class
local equipped = AbilityCondition.equipped(ID)
local exhaust: ServerSignal<nil> = VFXBinding.signal({ "Running" }, "Server", Type.none, { To = "Resting" })
local recover: ServerSignal<nil> = VFXBinding.signal({ "Resting" }, "Server", Type.none, { To = "Running" })
-- the avatar runs for as long as the tool is out + there's energy to run on. out of it the avatar walks until some
-- has come back, the tool doesn't have to be taken out again
local bindings: Bindings = {
	Start = VFXBinding.event({ "Walking" }, AbilityTrigger.started(equipped), { To = "Running" }),
	Sprint = VFXBinding.state({ "Running" }, AbilityTrigger.always()),
	Skim = VFXBinding.state({ "Running", "Resting" }, AbilityTrigger.always()),
	Exhaust = exhaust,
	Rest = VFXBinding.state({ "Resting" }, AbilityTrigger.always()),
	Recover = recover,
	Stop = VFXBinding.event({ "Running", "Resting" }, AbilityTrigger.stopped(equipped), { To = "Walking" }),
}
-- the run is the same in every game, how fast it is + what's seen + heard of it isn't
local ability: Ability = table.freeze({
	Layout = VFXBinding.layout(ID, "Walking", true, bindings),
	Config = GameDefinition.tune(table.freeze(CONFIG), {
		shl3 = FreezeUtil.delta(CONFIG, function(config: Config): Config
			-- nearly twice the pace, in silence
			config.WalkSpeed = 150
			config.Sound = nil
			-- the view only widens while the avatar is on the move, standing about with the tool out it's as it was
			config.FieldOfView = { FieldOfView = 100, Duration = 0.5, IsMoving = true }
			config.Wake = { Lifetime = 0.2, Depth = 0.5 }
			return config
		end),
		shl1 = FreezeUtil.delta(CONFIG, function(config: Config): Config
			-- the same pace, in silence
			config.WalkSpeed = 80
			config.Sound = nil
			return config
		end),
	}),
})

return ability
