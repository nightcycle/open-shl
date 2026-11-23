--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
local Harness = require("@game/ReplicatedStorage/Shared/Harness")
-- Types
-- Constants
-- Variables
-- References
-- Private Functions
-- Class
-- the arguments more than one area of the server takes
return table.freeze({
	Player = Harness.optional(
		Harness.newArgument(
			"Player",
			"string",
			Type.string,
			"the name of a player, whoever is alone on the server when left out"
		)
	),
	Body = Harness.optional(
		Harness.newArgument(
			"Body",
			"string",
			Type.string,
			"the name of a player or of a puppet, the avatar of whoever is alone on the server when left out"
		)
	),
})
