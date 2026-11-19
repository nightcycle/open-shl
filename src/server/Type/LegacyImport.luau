--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
-- Components
-- Hooks
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
type Result<V, E> = TypeUnionLib.Result<V, E>

local Types = {}

-- what superhero life 3 brings over for the section of its save, a field for a field
export type SHL3Patch = {
	OwnedItemIds: { string }?,
	ApartmentTier: number?,
	RedeemedCodeIds: { string }?,
}
Types.SHL3Patch = Type.strictInterface({
	OwnedItemIds = Type.optional(Type.array(Type.string)),
	ApartmentTier = Type.optional(Type.intersection(Type.integer, Type.numberMin(0))),
	RedeemedCodeIds = Type.optional(Type.array(Type.string)),
})

-- what a player had in the game this one replaces, in the shape of their save here. a field is only there when the
-- old stores held something for it. it's laid out the way the save is: what every game brings over, what superhero
-- life 2 does beside it + a section for each game that keeps one. a game only ever hands over its own
export type SavePatch = {
	Characters: { CharacterType.Character }?,
	ActiveCharacterId: string?,
	Balances: EconomyType.Balances?,
	Inventory: BaseType.BaseInventory?,
	BaseLayout: BaseType.BaseLayout?,
	IsTutorialEnabled: boolean?,
	LastDailyRewardAt: number?,
	SHL3: SHL3Patch?,
}
do -- Types.SHL2SavePatch, Types.SHL3SavePatch
	-- the patch of one game: what all of them bring over + what only it does
	local function newValidator(
		own: { [string]: (value: unknown) -> (boolean, string?) }
	): (value: unknown) -> (boolean, string?)
		local shape: { [string]: (value: unknown) -> (boolean, string?) } = {
			Characters = Type.optional(Type.array(CharacterType.Character)),
			ActiveCharacterId = Type.optional(Type.string),
			Balances = Type.optional(EconomyType.Balances),
		}
		for key, isField in own do
			shape[key] = isField
		end
		return Type.strictInterface(shape)
	end
	Types.SHL2SavePatch = newValidator({
		Inventory = Type.optional(BaseType.BaseInventory),
		BaseLayout = Type.optional(BaseType.BaseLayout),
		IsTutorialEnabled = Type.optional(Type.boolean),
		LastDailyRewardAt = Type.optional(Type.intersection(Type.integer, Type.numberMin(0))),
	})
	Types.SHL3SavePatch = newValidator({
		SHL3 = Type.optional(Types.SHL3Patch),
	})
end

-- the way into the stores of the game a game takes over from. which stores there are, what they hold + how that's read
-- is that game's own, so each has one of these to itself
export type Importer = {
	-- starts at 1 + goes up whenever what it brings over changes. a save keeps the version of the pass it had, so one
	-- that had an earlier pass (or none: the importer came after the save did) is asked for again
	Version: number,
	-- yields. a user the old stores hold nothing of gets an empty patch, an error means they couldn't be asked
	Import: (userId: number) -> Result<SavePatch, string>,
}
Types.Importer = Type.strictInterface({
	Version = Type.intersection(Type.integer, Type.numberMin(1)),
	Import = Type.callback,
})

return Types
