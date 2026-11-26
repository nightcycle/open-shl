--!strict
-- Services
-- Packages
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local LightningHand = require("@game/ReplicatedStorage/Shared/Ability/Library/Ranged/LightningHand")
local ShotFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Shot")
-- Types
-- Constants
local CONFIG: ShotFactory.Config = {
	CastAnimation = "PowerShot",
}
-- five a second leave the hand of shl1, no throw is over that soon: its avatar only holds the tool out
local SHL1_CONFIG: ShotFactory.Config = table.freeze({})
-- Variables
-- References
-- Private Functions
-- Class
return ShotFactory.new(LightningHand, GameDefinition.tune(CONFIG, { shl1 = SHL1_CONFIG })):Build()
