--!strict
-- Services
-- Packages
-- Modules
-- Types
local AbilityType = require("@game/ReplicatedStorage/Shared/Type/Ability")
type ClientDefinition = AbilityType.ClientDefinition
-- Constants
-- the client half of every ability the game has. the server keeps a list of its own, an ability is added to both
local DEFINITIONS: { ClientDefinition } = table.freeze({
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/AdvancedMelee/FirePunch"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/AdvancedMelee/ForceExplosion"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/AdvancedMelee/IceStorm"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/AdvancedMelee/Tornado"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/BasicMelee/BoStaff"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/BasicMelee/Claws"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/BasicMelee/DualKatana"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/BasicMelee/ForceBlast"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/BasicMelee/Hammer"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/BasicMelee/JungleKnife"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/BasicMelee/MartialArts"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/BasicMelee/Sword"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/BasicMelee/Trident"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/AssaultGun"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/Bow"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/FireHand"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/Handgun"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/IceHand"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/LaserEyes"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/LaserGun"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/LaserHand"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/LightningHand"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/MagicHand"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/ThrowingStar"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Special/Camouflage"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Special/ForceField"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Special/HealingFactor"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Special/Invisibility"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Special/Invulnerability"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Special/MindReading"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Transportation/Flight"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Transportation/Grapple"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Transportation/Portals"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Transportation/SuperSpeed"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Transportation/Teleport"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Transportation/WallClimb"),
})
-- Variables
-- References
-- Private Functions
-- Class
return DEFINITIONS
