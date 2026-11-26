--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local DisasterType = require("@game/ReplicatedStorage/Shared/Type/Disaster")
type Result<V, E> = TypeUnionLib.Result<V, E>
export type Disaster = DisasterType.Disaster
export type Consequence = DisasterType.Consequence
export type Blast = DisasterType.Blast
export type Rise = DisasterType.Rise
export type Fireball = DisasterType.Fireball
export type Rebuild = DisasterType.Rebuild
export type Bar = DisasterType.Bar
export type Catalogue = DisasterType.Catalogue
-- Constants
-- the disasters of a game are its own, a game without any never requires this
local CATALOGUE: Catalogue = GameDefinition.pick({
	shl1 = function(): Catalogue
		error(`shl1 has no disasters`)
	end,
	shl2 = function(): Catalogue
		error(`shl2 has no disasters`)
	end,
	shl3 = function(): Catalogue
		return require("@self/SHL3")
	end,
})
assert(DisasterType.Catalogue(CATALOGUE))
TableUtil.deepFreeze(CATALOGUE)
-- Variables
-- References
-- Private Functions
-- Class
-- what a map marks a target of is found in here by the id it's marked with. both sides read it: the server runs a
-- disaster, a client draws the bar over its target + what it sees of the fall
local Module = {}

Module.BAR = CATALOGUE.Bar

Module.get = function(id: string): Result<Disaster, string>
	local disaster: Disaster? = CATALOGUE.Disasters[id]
	if disaster then
		return Result.ok(disaster)
	end
	return Result.err(`no disaster "{id}"`)
end

-- every one of them by its id
Module.list = function(): { [string]: Disaster }
	return CATALOGUE.Disasters
end

return Module
