--!strict
-- Services
-- Packages
-- Modules
local DualKatana = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/DualKatana")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
-- Types
-- Constants
local CONFIG: MeleeFactory.Config = {
	DrawAnimation = "ClawSheathing",
	SwingAnimations = { "LeftSlash", "RightSlash" },
}
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(
	DualKatana,
	GameDefinition.tune(CONFIG, {
		-- its blades are drawn the way every weapon of it is
		shl3 = FreezeUtil.delta(CONFIG, function(config: MeleeFactory.Config): MeleeFactory.Config
			config.DrawAnimation = "Sheathing"
			config.SwingAnimations = { "LeftSlash", "RightSlash" }
			return config
		end),
	})
):Build()
