--!strict
-- Services
-- Packages
-- Modules
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ClientDefinition = AbilityType.ClientDefinition
-- Constants
local DEFINITIONS: { ClientDefinition } = {
	require("@self/AdvancedMelee/FirePunch"),
	require("@self/AdvancedMelee/ForceExplosion"),
	require("@self/AdvancedMelee/IceStorm"),
	require("@self/AdvancedMelee/Tornado"),
	require("@self/BasicMelee/BoStaff"),
	require("@self/BasicMelee/Claws"),
	require("@self/BasicMelee/DualKatana"),
	require("@self/BasicMelee/ForceBlast"),
	require("@self/BasicMelee/Hammer"),
	require("@self/BasicMelee/JungleKnife"),
	require("@self/BasicMelee/MartialArts"),
	require("@self/BasicMelee/Sword"),
	require("@self/BasicMelee/Trident"),
	require("@self/Ranged/AssaultGun"),
	require("@self/Ranged/Bow"),
	require("@self/Ranged/FireHand"),
	require("@self/Ranged/Handgun"),
	require("@self/Ranged/IceHand"),
	require("@self/Ranged/LaserEyes"),
	require("@self/Ranged/LaserGun"),
	require("@self/Ranged/LaserHand"),
	require("@self/Ranged/LightningHand"),
	require("@self/Ranged/MagicHand"),
	require("@self/Ranged/ThrowingStar"),
	require("@self/Special/Camouflage"),
	require("@self/Special/ForceField"),
	require("@self/Special/HealingFactor"),
	require("@self/Special/Invisibility"),
	require("@self/Special/Invulnerability"),
	require("@self/Special/MindReading"),
	require("@self/Transportation/Flight"),
	require("@self/Transportation/Grapple"),
	require("@self/Transportation/Portals"),
	require("@self/Transportation/SuperSpeed"),
	require("@self/Transportation/Teleport"),
	require("@self/Transportation/WallClimb"),
}
-- Variables
local DefinitionsById: { [string]: ClientDefinition } = {}
-- References
-- Private Functions
-- Class
local Module = {}

for _, definition in DEFINITIONS do
	local id = definition.Layout.Id
	assert(DefinitionsById[id] == nil, `the client half of "{id}" is defined twice`)
	DefinitionsById[id] = definition
end

-- nil for an ability that isn't built yet
Module.get = function(id: string): ClientDefinition?
	return DefinitionsById[id]
end

return Module
