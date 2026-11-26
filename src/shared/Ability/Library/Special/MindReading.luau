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
type EventBinding = AbilityType.EventBinding
type StateBinding = AbilityType.StateBinding
export type Bindings = {
	Read: StateBinding, -- the player looks in on somebody else
	Next: EventBinding?, -- a click moves on to the next of them, in a game that picks who with its buttons there's none
}
-- Constants
local ID = "special_mind-reading"
-- Variables
-- References
-- Private Functions
-- Class
-- for as long as the tool is out the player sees the world the way the others do: through a camera on them
local equipped = AbilityCondition.equipped(ID)
local bindings: Bindings = {
	Read = VFXBinding.state({ "Idle" }, AbilityTrigger.active(equipped)),
	-- it leads nowhere: the machine stays where it is
	Next = GameDefinition.tune(nil :: EventBinding?, {
		shl3 = VFXBinding.event(
			{ "Idle" },
			AbilityTrigger.during(AbilityTrigger.started(AbilityCondition.PRIMARY), AbilityTrigger.active(equipped))
		),
	}),
}

return table.freeze({
	Layout = VFXBinding.layout(ID, "Idle", true, bindings),
})
