--!strict
-- Services
-- Packages
-- Modules
local BoStaff = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/BoStaff")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
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
	BoStaff,
	GameDefinition.tune(CONFIG, {
		-- it comes out without a flourish + is swung from one side or the other
		shl1 = FreezeUtil.delta(CONFIG, function(config: MeleeFactory.Config): MeleeFactory.Config
			config.DrawAnimation = nil
			config.SwingAnimations = { "RightSlash", "LeftSlash" }
			return config
		end),
	})
):Build()
