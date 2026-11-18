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
	Read: StateBinding, -- the player looks in on somebody else
}
-- Constants
local ID = "special_mind-reading"
-- Variables
-- References
-- Private Functions
-- Class
-- for as long as the tool is out the player sees the world the way the others do: through a camera on them
local bindings: Bindings = {
	Read = VFXBinding.state({ "Idle" }, AbilityTrigger.active(AbilityCondition.equipped(ID))),
}

return table.freeze({
	Layout = VFXBinding.layout(ID, "Idle", true, bindings),
})
