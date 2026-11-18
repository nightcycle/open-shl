--!strict
-- Services
-- Packages
-- Modules
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ServerDefinition = AbilityType.ServerDefinition
-- Constants
-- the server half of every ability the game has. the client keeps a list of its own, an ability is added to both
local DEFINITIONS: { ServerDefinition } = table.freeze({
	require("@game/ServerScriptService/Server/Ability/Library/AdvancedMelee/FirePunch"),
	require("@game/ServerScriptService/Server/Ability/Library/AdvancedMelee/ForceExplosion"),
	require("@game/ServerScriptService/Server/Ability/Library/AdvancedMelee/IceStorm"),
	require("@game/ServerScriptService/Server/Ability/Library/AdvancedMelee/Tornado"),
	require("@game/ServerScriptService/Server/Ability/Library/BasicMelee/BoStaff"),
	require("@game/ServerScriptService/Server/Ability/Library/BasicMelee/Claws"),
	require("@game/ServerScriptService/Server/Ability/Library/BasicMelee/DualKatana"),
	require("@game/ServerScriptService/Server/Ability/Library/BasicMelee/ForceBlast"),
	require("@game/ServerScriptService/Server/Ability/Library/BasicMelee/Hammer"),
	require("@game/ServerScriptService/Server/Ability/Library/BasicMelee/JungleKnife"),
	require("@game/ServerScriptService/Server/Ability/Library/BasicMelee/MartialArts"),
	require("@game/ServerScriptService/Server/Ability/Library/BasicMelee/Sword"),
	require("@game/ServerScriptService/Server/Ability/Library/BasicMelee/Trident"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/AssaultGun"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/Bow"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/FireHand"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/Handgun"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/IceHand"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/LaserEyes"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/LaserGun"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/LaserHand"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/LightningHand"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/MagicHand"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/ThrowingStar"),
	require("@game/ServerScriptService/Server/Ability/Library/Special/Camouflage"),
	require("@game/ServerScriptService/Server/Ability/Library/Special/ForceField"),
	require("@game/ServerScriptService/Server/Ability/Library/Special/HealingFactor"),
	require("@game/ServerScriptService/Server/Ability/Library/Special/Invisibility"),
	require("@game/ServerScriptService/Server/Ability/Library/Special/Invulnerability"),
	require("@game/ServerScriptService/Server/Ability/Library/Special/MindReading"),
	require("@game/ServerScriptService/Server/Ability/Library/Transportation/Flight"),
	require("@game/ServerScriptService/Server/Ability/Library/Transportation/Grapple"),
	require("@game/ServerScriptService/Server/Ability/Library/Transportation/Portals"),
	require("@game/ServerScriptService/Server/Ability/Library/Transportation/SuperSpeed"),
	require("@game/ServerScriptService/Server/Ability/Library/Transportation/Teleport"),
	require("@game/ServerScriptService/Server/Ability/Library/Transportation/WallClimb"),
})
-- Variables
-- References
-- Private Functions
-- Class
return DEFINITIONS
