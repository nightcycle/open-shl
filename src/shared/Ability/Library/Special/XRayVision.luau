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
	See: StateBinding, -- the player sees through what's around them
}
-- Constants
local ID = "special_x-ray-vision"
-- Variables
-- References
-- Private Functions
-- Class
-- for as long as the tool is out the player sees through what's around them, a layer at a time. there's nothing to
-- click + nothing it costs
local bindings: Bindings = {
	See = VFXBinding.state({ "Idle" }, AbilityTrigger.active(AbilityCondition.equipped(ID))),
}

return table.freeze({
	Layout = VFXBinding.layout(ID, "Idle", true, bindings),
})
