--!strict
-- Services
-- Packages
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local MartialArts = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/MartialArts")
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
-- Types
-- Constants
local CONFIG: MeleeFactory.Config = {
	SwingAnimations = { "PowerPunch", "Strike", "RightFootKick" },
	IsRooted = true,
}
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(
	MartialArts,
	GameDefinition.tune(CONFIG, {
		-- its avatar walks on through a move
		shl3 = FreezeUtil.delta(CONFIG, function(config: MeleeFactory.Config): MeleeFactory.Config
			config.SwingAnimations = { "PowerPunch", "RightFootKick", "Strike" }
			config.IsRooted = false
			return config
		end),
	})
):Build()
