--!strict
-- Services
-- Packages
-- Modules
local FreezeUtil = require("@game/ReplicatedStorage/Shared/Util/Freeze")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local ToggleFactory = require("@game/ReplicatedStorage/Shared/Ability/Factory/Toggle")
local VFXAssetDefinition = require("@game/ReplicatedStorage/Shared/Definition/VFXAsset")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
type SoundKey = VFXAssetDefinition.SoundKey
type Sounds = {
	Cast: SoundKey,
	Finish: SoundKey,
}
-- Constants
local CONFIG: ToggleFactory.Config = {
	Duration = 20,
}
-- what every machine makes of the avatar + what it's heard going + coming back with
local CLOAK: ClientVFXType.Cloak = table.freeze({ Transparency = 1 })
local GAME_CLOAK: ClientVFXType.Cloak = GameDefinition.tune(CLOAK, {
	-- it eases out + back in, whatever it glows with goes out with it
	shl3 = table.freeze({ Transparency = 1, FadeDuration = 0.5, IsUnlit = true }),
})
local SOUNDS: Sounds = { Cast = "Morph", Finish = "MorphReset" }
-- shl3 has it go + come back with the swish of a blade
local SHL3_SOUNDS: Sounds = { Cast = "Slash", Finish = "Slash" }
local GAME_SOUNDS: Sounds = GameDefinition.tune(SOUNDS, { shl3 = SHL3_SOUNDS })
-- Variables
-- References
-- Private Functions
-- Class
-- a click with the tool out takes the avatar out of sight for as long as it's on. going is the same in every game,
-- how long for + what it looks + sounds like isn't
local ability = ToggleFactory.new(
	"special_invisibility",
	GameDefinition.tune(CONFIG, {
		shl3 = FreezeUtil.delta(CONFIG, function(config: ToggleFactory.Config): ToggleFactory.Config
			-- it's on until it's turned off: nothing counts down, so its time is one that never comes
			config.Duration = 30000000000
			-- half a second to come back in, then five more
			config.Cooldown = 5.5
			return config
		end),
	})
)

return table.freeze({
	Layout = ability.Layout,
	Config = ability.Config,
	Cloak = GAME_CLOAK,
	CastSound = GAME_SOUNDS.Cast,
	FinishSound = GAME_SOUNDS.Finish,
})
