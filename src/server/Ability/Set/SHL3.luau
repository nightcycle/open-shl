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
	require("@game/ServerScriptService/Server/Ability/Library/BasicMelee/Claws"),
	require("@game/ServerScriptService/Server/Ability/Library/BasicMelee/DualKatana"),
	require("@game/ServerScriptService/Server/Ability/Library/BasicMelee/MartialArts"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/FireRay"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/FreezeRay"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/HitscanBow"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/LaserRay"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/Lightning"),
	require("@game/ServerScriptService/Server/Ability/Library/Ranged/Minigun"),
	require("@game/ServerScriptService/Server/Ability/Library/Special/ForceShield"),
	require("@game/ServerScriptService/Server/Ability/Library/Special/Invisibility"),
	require("@game/ServerScriptService/Server/Ability/Library/Special/XRayVision"),
	require("@game/ServerScriptService/Server/Ability/Library/Transportation/Flight"),
	require("@game/ServerScriptService/Server/Ability/Library/Transportation/Grapple"),
	require("@game/ServerScriptService/Server/Ability/Library/Transportation/SuperSpeed"),
})
-- Variables
-- References
-- Private Functions
-- Class
return DEFINITIONS
