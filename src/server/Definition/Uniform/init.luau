--!strict
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
local Result = TypeUnionLib.Result
-- Modules
local GameDefinition = require("@game/ReplicatedStorage/Shared/Definition/Game")
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
type Result<V, E> = TypeUnionLib.Result<V, E>
type Item = AppearanceType.Item
-- what a prop of the map dresses whoever touches it in
export type UniformDefinition = {
	Id: string,
	Items: { Item },
}
-- the outfits of a game, by the id its map marks a prop with
type Catalogue = {
	get: (id: string) -> Result<UniformDefinition, string>,
}
-- Constants
local isUniformDefinition = Type.strictInterface({
	Id = Type.string,
	Items = Type.array(AppearanceType.Item),
})
-- the outfits of a game are its own: where one of them reads them from is never waited on in another
local CATALOGUE: Catalogue = GameDefinition.pick({
	shl1 = function(): Catalogue
		error(`shl1 has no outfit pads`)
	end,
	shl2 = function(): Catalogue
		return require("@self/SHL2")
	end,
	shl3 = function(): Catalogue
		return require("@self/SHL3")
	end,
})
-- Variables
-- References
-- Private Functions
-- Class
local Module = {}

Module.get = function(id: string): Result<UniformDefinition, string>
	local uniformRes = CATALOGUE.get(id)
	if uniformRes.IsOk then
		-- however a game came by an outfit, it's one before anybody is dressed in it
		local success, msg = isUniformDefinition(uniformRes.Value)
		if not success then
			return Result.err(`get "{id}" failed type validation: {msg}`)
		end
	end
	return uniformRes
end

return Module
