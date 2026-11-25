--!strict
-- Services
-- Packages
-- Modules
local PropDefinition = require("@game/ReplicatedStorage/Shared/Definition/Prop")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type AnimationKey = VFXAssetDefinition.AnimationKey
-- what both halves of a prop that's only ever held have to agree on
export type Held = {
	Prop: PropDefinition.PropDefinition,
	Look: ClientVFXType.Prop, -- what's in the hand for as long as it's out
	HoldAnimation: AnimationKey,
}
-- Constants
-- the arm out in front, what a hand that holds anything used to do by itself
local HOLD_ANIMATION: AnimationKey = "GunHolding"
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

-- a prop there's nothing to but being held: it's in the hand or it isn't, a click with it is nothing. whatever it
-- does to the world, somebody else asks the server who holds one
Module.new = function(id: string, look: ClientVFXType.Prop): Held
	local definitionRes = PropDefinition.get(id)
	assert(definitionRes.IsOk, `no prop is registered as "{id}"`)
	assert(definitionRes.Value.Use == nil, `"{id}" is clicked with, there's more to it than being held`)
	return table.freeze({
		Prop = definitionRes.Value,
		Look = table.freeze(table.clone(look)),
		HoldAnimation = HOLD_ANIMATION,
	})
end

return Module
