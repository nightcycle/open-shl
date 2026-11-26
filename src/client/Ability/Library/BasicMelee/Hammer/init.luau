--!strict
-- Services
-- Packages
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local Hammer = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/Hammer")
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
-- Types
-- Constants
local CONFIG: MeleeFactory.Config = {
	DrawAnimation = "Sheathing",
	SwingAnimations = { "KnifeJab", "KnifeSlash" },
}
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(
	Hammer,
	GameDefinition.tune(CONFIG, {
		-- it comes out without a flourish + has the one swing
		shl1 = FreezeUtil.delta(CONFIG, function(config: MeleeFactory.Config): MeleeFactory.Config
			config.DrawAnimation = nil
			config.SwingAnimations = { "RightSlash" }
			return config
		end),
	})
):Build()
