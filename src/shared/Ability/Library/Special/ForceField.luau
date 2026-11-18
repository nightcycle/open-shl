--!strict
-- Services
-- Packages
-- Modules
local AbilityCondition = require("@game/ReplicatedStorage/Shared/Constructor/AbilityCondition")
local AbilityTrigger = require("@game/ReplicatedStorage/Shared/Constructor/AbilityTrigger")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
local VFXBinding = require("@game/ReplicatedStorage/Shared/Constructor/VFXBinding")
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type EventBinding = AbilityType.EventBinding
export type Bindings = {
	Cast: EventBinding,
	Rise: EventBinding, -- the wall goes up, where the click that cast it pointed
	Recover: EventBinding,
}
-- Constants
local ID = "special_force-field"
-- seconds from the click until the wall is up
local RISE_DELAY = 0.2
-- seconds from the click until the next one counts
local COOLDOWN = 2.1
-- what the wall is heard going up with, on both sides
local SOUND: VFXAssetDefinition.SoundKey = "Platforming"
-- Variables
-- References
-- Private Functions
-- Class
-- a click with the tool out puts a wall of light up where the player points. the tool can be put away right after:
-- the wall still goes up + the next one still has to wait
local bindings: Bindings = {
	Cast = VFXBinding.event(
		{ "Idle" },
		AbilityTrigger.during(
			AbilityTrigger.started(AbilityCondition.PRIMARY),
			AbilityTrigger.active(AbilityCondition.equipped(ID))
		),
		{ To = "Casting" }
	),
	Rise = VFXBinding.event({ "Casting" }, AbilityTrigger.after(RISE_DELAY)),
	Recover = VFXBinding.event({ "Casting" }, AbilityTrigger.after(COOLDOWN), { To = "Idle" }),
}

return table.freeze({
	Layout = VFXBinding.layout(ID, "Idle", true, bindings),
	Sound = SOUND,
})
