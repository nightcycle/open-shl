--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
-- Modules
local Animation = require("@game/ReplicatedStorage/Generated/Animation")
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Types
local TransitionType = require("@game/ReplicatedStorage/Shared/Type/Transition")
export type EffectDefinition = TransitionType.EffectDefinition
export type TransformationDefinition = TransitionType.TransformationDefinition
export type DeathDefinition = TransitionType.DeathDefinition
type TransitionCatalogue = TransitionType.TransitionCatalogue
-- Constants
-- one of the two plays when a hit leaves the character standing
local FLINCH = table.freeze({
	ANIMATION_IDS = table.freeze({
		Animation.core.transition["flinch-1.rbxm"],
		Animation.core.transition["flinch-2.rbxm"],
	}),
	DURATION = 0.4,
})
local DEFAULT_TRANSFORMATION_STYLE: PseudoEnum.TransformationStyle = PseudoEnum.TransformationStyle.Spin
local DEFAULT_DEATH_STYLE: PseudoEnum.DeathStyle = PseudoEnum.DeathStyle.FallForward
-- what a character swaps + dies by is the game's own, the rows of another game are never required
local CATALOGUE: TransitionCatalogue = GameDefinition.pick({
	shl1 = function(): TransitionCatalogue
		return require("@self/SHL1")
	end,
	shl2 = function(): TransitionCatalogue
		return require("@self/SHL2")
	end,
	shl3 = function(): TransitionCatalogue
		return require("@self/SHL3")
	end,
})
assert(TransitionType.TransitionCatalogue(CATALOGUE))
TableUtil.deepFreeze(CATALOGUE)
local TRANSFORMATIONS = CATALOGUE.Transformations
-- the character lies where it fell for the length of the animation, it never dies as far as roblox can tell
local DEATHS = CATALOGUE.Deaths
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

for style, DEFINITION in TRANSFORMATIONS do
	assert(DEFINITION.Style == style, `"{style}" transformation is filed under the wrong style`)
end
for style, DEFINITION in DEATHS do
	assert(DEFINITION.Style == style, `"{style}" death is filed under the wrong style`)
end
-- every character starts out with these two, so every game has a row for them
assert(
	TRANSFORMATIONS[DEFAULT_TRANSFORMATION_STYLE] ~= nil,
	`the game has no "{DEFAULT_TRANSFORMATION_STYLE}" transformation`
)
assert(DEATHS[DEFAULT_DEATH_STYLE] ~= nil, `the game has no "{DEFAULT_DEATH_STYLE}" death`)

Module.DEFAULT_TRANSFORMATION_STYLE = DEFAULT_TRANSFORMATION_STYLE
Module.DEFAULT_DEATH_STYLE = DEFAULT_DEATH_STYLE
Module.FLINCH = FLINCH

-- a style is picked on a page of the editor. a game whose editor has no such page has no row for it + plays the one
-- every character starts out with, whatever its character holds: a client can hand one in with any style there is
Module.getTransformation = function(style: PseudoEnum.TransformationStyle?): TransformationDefinition
	return TRANSFORMATIONS[style or DEFAULT_TRANSFORMATION_STYLE] or TRANSFORMATIONS[DEFAULT_TRANSFORMATION_STYLE]
end

Module.getDeath = function(style: PseudoEnum.DeathStyle?): DeathDefinition
	return DEATHS[style or DEFAULT_DEATH_STYLE] or DEATHS[DEFAULT_DEATH_STYLE]
end

-- the ones the game has, in the order of the styles
Module.listTransformations = function(): { TransformationDefinition }
	local out: { TransformationDefinition } = {}
	for _, style: PseudoEnum.TransformationStyle in PseudoEnum.getEnumItems("TransformationStyle") do
		local definition: TransformationDefinition? = TRANSFORMATIONS[style]
		if definition then
			table.insert(out, definition)
		end
	end
	table.freeze(out)
	return out
end

Module.listDeaths = function(): { DeathDefinition }
	local out: { DeathDefinition } = {}
	for _, style: PseudoEnum.DeathStyle in PseudoEnum.getEnumItems("DeathStyle") do
		local definition: DeathDefinition? = DEATHS[style]
		if definition then
			table.insert(out, definition)
		end
	end
	table.freeze(out)
	return out
end

return Module
