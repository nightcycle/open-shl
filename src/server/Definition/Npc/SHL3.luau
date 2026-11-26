--!strict
-- Services
-- Packages
-- Modules
local Image = require("@game/ReplicatedStorage/Generated/Image")
-- Types
local NpcType = require("@game/ServerScriptService/Server/Type/Npc")
type Npc = NpcType.Npc
-- Constants
-- roblox's own zombie pack, the one its old place had under the rig's Animate. it's nobody's to download or to
-- upload again, so the ids are written out here instead of being files under asset/animation
local ANIMATION_URL = "rbxassetid://%d"
-- Variables
-- References
-- Private Functions
local function newAnimation(id: number): string
	return string.format(ANIMATION_URL, id)
end
-- Class
-- what rises from the graves. every number is its old place's: 40 health against hits of 10 to 35, faster on foot
-- than an avatar, a look around every 7 studs of walking with a ray as long. it goes after heroes + hurts whoever its
-- arms brush, one touch for the whole of it every second + a half. new: it's gone a moment after it went down (the
-- script that was to do that only ever asked as it came in), + its face is the game's own upload
local ZOMBIE: Npc = table.freeze({
	Id = "zombie",
	MaxHealth = 40,
	WalkSpeed = 20,
	WakeDistance = 7,
	StartDelay = table.freeze({ Min = 1, Max = 2 }),
	Sight = 600,
	PreyTeamId = "Heroes" :: "Heroes",
	Probe = table.freeze({
		Length = 7,
		Side = 1,
		Drop = 0.5,
		Lean = 2,
		Rise = 2,
		StepUp = 4.5,
		EdgeAhead = 0.85,
		EdgeDepth = 7,
		Level = 3,
		Stuck = 1,
		Stride = 100,
	}),
	Damage = 15,
	DamageCooldown = 1.5,
	-- both halves of both arms, the hands aren't among them
	ArmPattern = "Arm",
	Regeneration = table.freeze({ Fraction = 0.01, Interval = 1 }),
	RemoveDelay = 1.5,
	Animations = table.freeze({
		Idles = table.freeze({
			table.freeze({ AnimationId = newAnimation(616158929), Weight = 9 }),
			table.freeze({ AnimationId = newAnimation(616160636), Weight = 1 }),
		}),
		Walk = newAnimation(616168032),
		WalkPace = 15,
		Jump = newAnimation(616161997),
		Fall = newAnimation(616157476),
		Climb = newAnimation(616156119),
		ClimbPace = 5,
	}),
	Face = table.freeze({
		Name = "Zombie Face",
		Image = Image["shl-3"].npc["zombie-face.png"],
	}),
})

return table.freeze({
	-- a wave of them, all the map has graves for
	MaxCount = 18,
	Npcs = table.freeze({ ZOMBIE }),
})
