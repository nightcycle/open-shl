--!strict
-- Services
-- Packages
-- Modules
-- Types
local DisasterType = require("@game/ReplicatedStorage/Shared/Type/Disaster")
type Catalogue = DisasterType.Catalogue
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the two things of valor city its villains wear down, every number as its old place had it. the refinery pays half
-- as much again for a point of health as the graveyard + has half of its health. the old place counted every hit
-- at its full amount, on a target that was down as well: here a point is paid for once, while it's there to take
local Catalogue: Catalogue = {
	Disasters = {
		-- a body walks out of every grave the map marks, all over the city: one wave of them, gone before the
		-- graveyard stands again
		ZombieApocalypse = {
			MaxHealth = 2000,
			PoolScale = 3,
			GuardTeamId = "Heroes",
			Alert = "Villains are trying to start a zombie apocalypse at the graveyard!",
			Consequence = {
				Type = "Rise",
				NpcId = "zombie",
				SmokeDuration = 5,
				Offset = Vector3.new(0, 4, 0),
				Lifetime = 90,
				ResetDelay = 600,
			},
			IsArmed = true,
		},
		RefineryExplosion = {
			MaxHealth = 1000,
			PoolScale = 4.5,
			GuardTeamId = "Heroes",
			Alert = "Villains are trying to blow up the refinery!",
			Consequence = {
				Type = "Blast",
				-- the old place asked for 1000, the engine never went past 100
				Radius = 100,
				Pressure = 100000000,
				DebrisLifetime = 10,
				DebrisTeamId = "Heroes",
				-- eleven times as wide as what it throws anything about in
				Fireball = {
					Size = 1100,
					GrowDuration = 0.47,
					FadeDuration = 0.7,
					Lifetime = 1,
					Color = Color3.fromRGB(218, 133, 65),
				},
				-- a look every ten minutes of the server's life, so it's gone for anything from 10 seconds to 10 minutes
				Rebuild = {
					FirstDelay = 30,
					Interval = 600,
					Depth = 200,
					RiseDuration = 12,
				},
			},
			IsArmed = true,
		},
	},
	Bar = {
		FlashDuration = 0.15,
		FlashColor = Color3.fromRGB(255, 0, 0),
		Color = Color3.fromRGB(0, 255, 0),
	},
}

return Catalogue
