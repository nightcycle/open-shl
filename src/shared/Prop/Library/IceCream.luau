--!strict
-- Services
-- Packages
-- Modules
local ConsumableFactory = require("@game/ReplicatedStorage/Shared/Prop/Factory/Consumable")
-- Types
local ClientVFXType = require("@game/ReplicatedStorage/Shared/Type/ClientVFX")
-- Constants
-- what a lick that came too soon puts on the screen of whoever took it, the way the old gear had it: red, for 2 s
local NOTICE: ClientVFXType.Notice = table.freeze({
	Text = "BRAINFREEZE!",
	Color = Color3.new(1, 0, 0),
	Duration = 2,
})
-- Variables
-- References
-- Private Functions
-- Class
-- a cone off a picnic table in the park: a click is a lick of half a second, heard as it's over. a lick that comes
-- within 2 s of the one before it hurts whoever took it. the old one meant to + never did past its second lick: its
-- script stalled there for good. the race it ran on a sugar rush never ran in the old place + isn't here
return table.freeze({
	Consumable = ConsumableFactory.new("ice-cream", {
		Size = Vector3.new(0.63, 0.74, 1.54),
		Mesh = "IceCream",
		MeshScale = Vector3.one * 0.5,
		-- of the hand from the cone, the way the old tool gripped it: stood up out in front
		RestOffset = CFrame.new(-0.011, -0.169, -0.365, 1, 0, 0, 0, -1, 0, 0, 0, -1),
		-- stood up at the mouth for as long as a lick takes: its top where the burger is bitten. the old one played
		-- an animation no body of today has the arms for
		UseOffset = CFrame.new(1.489, 0.205, 0.068, 1, 0, 0, 0, -1, 0, 0, 0, -1),
		UseSound = "IceCreamLick",
	}),
	-- seconds a lick has to come after the one before it to cost nothing
	LickGap = 2,
	-- the health one that comes sooner takes off whoever licked
	LickCost = 30,
	Notice = NOTICE,
})
