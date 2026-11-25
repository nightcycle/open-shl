--!strict
-- Services
-- Packages
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type StateBinding = AbilityType.StateBinding
export type Bindings = {
	Hold: StateBinding, -- the shield is up
}
export type Config = {
	Size: Vector3,
	Offset: CFrame, -- of the shield from the root of whoever carries it
	Color: Color3, -- what it's in for a character that wears the power in none
	Transparency: number,
	FadeDuration: number, -- seconds it takes to show + to go
	Delay: number, -- seconds from when the tool is out until it's there
	Linger: number, -- seconds it stays once the tool is put away, before it goes
}
-- Constants
local ID = "special_force-shield"
-- five studs ahead + one up: it covers whoever carries it from head to foot + whoever stands close behind them
local CONFIG: Config = table.freeze({
	Size = Vector3.new(12, 7, 0.2),
	Offset = CFrame.new(0, 1, -5),
	Color = Color3.new(0, 1, 1),
	Transparency = 0.7,
	FadeDuration = 0.5,
	Delay = 0.3,
	Linger = 0.3,
})
-- Variables
-- References
-- Private Functions
-- Class
-- for as long as the tool is out a shield stands ahead of the player: there's nothing to click, nothing it costs +
-- nothing it does but be in the way
local bindings: Bindings = {
	Hold = VFXBinding.state({ "Idle" }, AbilityTrigger.active(AbilityCondition.equipped(ID))),
}

return table.freeze({
	Layout = VFXBinding.layout(ID, "Idle", true, bindings),
	Config = CONFIG,
})
