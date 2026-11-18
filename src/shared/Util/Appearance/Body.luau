--!strict
-- Services
-- Packages
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local HumanoidDescriptionBuilder = require("@game/ReplicatedStorage/Shared/Builder/HumanoidDescription")
type Builder = HumanoidDescriptionBuilder.Builder
-- how far a body leans to the two taller builds a description knows
type Build = {
	BodyType: number,
	Proportion: number,
}
-- Constants
-- the pieces of a game are fitted to the body it builds. a game that names no build has the one a description comes
-- with, which is the body the pieces of shl2 were fitted to
local BUILD: Build? = GameDefinition.tune(nil :: Build?, {
	-- the plain block body: next to it the one a description comes with has arms a quarter + legs nearly a third longer
	shl3 = table.freeze({ BodyType = 0, Proportion = 0 }),
})
-- Variables
-- References
-- Private Functions
-- Class
local Util = {}

-- the body of the game onto a description
function Util.describe(builder: Builder): Builder
	if BUILD then
		builder = builder:addScale(BUILD.BodyType, "BodyType"):addScale(BUILD.Proportion, "Proportion")
	end
	return builder
end

return Util
