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
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/BasicMelee/Claws"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/BasicMelee/DualKatana"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/BasicMelee/MartialArts"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/HitscanBow"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/LaserRay"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Ranged/Minigun"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Special/ForceShield"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Special/Invisibility"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Special/XRayVision"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Transportation/Flight"),
	require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Library/Transportation/SuperSpeed"),
})
-- Variables
-- References
-- Private Functions
-- Class
return DEFINITIONS
