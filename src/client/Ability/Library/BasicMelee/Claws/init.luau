--!strict
-- Services
-- Packages
-- Modules
local Claws = require("@game/ReplicatedStorage/Shared/Ability/Library/BasicMelee/Claws")
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local MeleeFactory = require("@game/StarterPlayer/StarterPlayerScripts/Client/Ability/Factory/Melee")
-- Types
-- Constants
local CONFIG: MeleeFactory.Config = {
	SwingAnimations = { "LeftSlash", "RightSlash" },
}
-- Variables
-- References
-- Private Functions
-- Class
return MeleeFactory.new(
	Claws,
	GameDefinition.tune(CONFIG, {
		-- its claws come out + go back with a flourish
		shl3 = FreezeUtil.delta(CONFIG, function(config: MeleeFactory.Config): MeleeFactory.Config
			config.DrawAnimation = "Sheathing"
			config.SwingAnimations = { "LeftSlash", "RightSlash" }
			return config
		end),
	})
):Build()
