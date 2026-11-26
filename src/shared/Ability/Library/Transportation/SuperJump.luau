--!strict
-- Services
-- Packages
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type StateBinding = AbilityType.StateBinding
type Layout<B> = AbilityType.Layout<B>
export type Bindings = {
	Hold: StateBinding, -- the tool is out
}
-- what a jump is made of while the tool is out, each game has its own way of going high
export type Config = {
	JumpPower: number?, -- what the avatar jumps with, what it always does without
	AirSpeed: number?, -- studs a second it moves at from a jump until it's down, its own pace without
	Float: number?, -- the share of its weight the avatar is rid of, none without
}
export type Ability = {
	Layout: Layout<Bindings>,
	Config: Config,
}
-- Constants
local ID = "transportation_super-jump"
local CONFIG: Config = table.freeze({})
-- a leap of some 230 studs, at the pace of a run until it's over
local SHL3_CONFIG: Config = table.freeze({ JumpPower = 300, AirSpeed = 80 })
-- four fifths of its weight are gone: it goes five times as high + comes down as slowly
local SHL1_CONFIG: Config = table.freeze({ Float = 0.8 })
-- Variables
-- References
-- Private Functions
-- Class
-- nothing is clicked: for as long as the tool is out the avatar jumps the way its game has a hero jump
local bindings: Bindings = {
	Hold = VFXBinding.state({ "Idle" }, AbilityTrigger.active(AbilityCondition.equipped(ID))),
}
local ability: Ability = table.freeze({
	Layout = VFXBinding.layout(ID, "Idle", true, bindings),
	Config = GameDefinition.tune(CONFIG, { shl3 = SHL3_CONFIG, shl1 = SHL1_CONFIG }),
})

return ability
