--!strict
-- Services
-- Packages
local TableUtil = require("@game/ReplicatedStorage/Packages/TableUtil")
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local NpcType = require("@game/ServerScriptService/Server/Type/Npc")
type Result<V, E> = TypeUnionLib.Result<V, E>
export type Npc = NpcType.Npc
-- the bodies nobody plays of a game
type Catalogue = {
	-- how many of them walk the map at once, at most
	MaxCount: number,
	Npcs: { Npc },
}
-- Constants
local isCatalogue = Type.strictInterface({
	MaxCount = Type.intersection(Type.integer, Type.numberPositive),
	Npcs = Type.array(NpcType.Npc),
})
-- the walkers of a game are its own, the catalogue of another game is never required
local CATALOGUE: Catalogue = GameDefinition.pick({
	shl1 = function(): Catalogue
		error(`shl1 has no bodies nobody plays`)
	end,
	shl2 = function(): Catalogue
		error(`shl2 has no bodies nobody plays`)
	end,
	shl3 = function(): Catalogue
		return require("@self/SHL3")
	end,
})
assert(isCatalogue(CATALOGUE))
TableUtil.deepFreeze(CATALOGUE)
local NPCS: { [string]: Npc } = {}
for _, npc in CATALOGUE.Npcs do
	assert(not NPCS[npc.Id], `the npc "{npc.Id}" is listed twice`)
	assert(
		npc.StartDelay.Min <= npc.StartDelay.Max,
		`"{npc.Id}" starts {npc.StartDelay.Min} to {npc.StartDelay.Max} s in`
	)
	assert(#npc.Animations.Idles > 0, `"{npc.Id}" has no way to stand about`)
	NPCS[npc.Id] = npc
end
table.freeze(NPCS)
-- Variables
-- References
-- Private Functions
-- Class
-- server only: a client is sent a model + what the server plays on it, it's told nothing of what makes one walk
local Module = {}

Module.MAX_COUNT = CATALOGUE.MaxCount

Module.list = function(): { Npc }
	return CATALOGUE.Npcs
end

Module.get = function(id: string): Result<Npc, string>
	local npc = NPCS[id]
	if npc then
		return Result.ok(npc)
	end
	return Result.err(`no npc "{id}"`)
end

return Module
