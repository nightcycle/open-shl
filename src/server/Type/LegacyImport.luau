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

-- what a player had in the game this one replaces, in the shape of their save here. a field is only there when the
-- old stores held something for it, it takes the place of what the save starts out with
export type SavePatch = {
	Characters: { CharacterType.Character }?,
	ActiveCharacterId: string?,
	Balances: EconomyType.Balances?,
	Inventory: BaseType.BaseInventory?,
	BaseLayout: BaseType.BaseLayout?,
	IsTutorialEnabled: boolean?,
	LastDailyRewardAt: number?,
}
Types.SavePatch = Type.strictInterface({
	Characters = Type.optional(Type.array(CharacterType.Character)),
	ActiveCharacterId = Type.optional(Type.string),
	Balances = Type.optional(EconomyType.Balances),
	Inventory = Type.optional(BaseType.BaseInventory),
	BaseLayout = Type.optional(BaseType.BaseLayout),
	IsTutorialEnabled = Type.optional(Type.boolean),
	LastDailyRewardAt = Type.optional(Type.intersection(Type.integer, Type.numberMin(0))),
})

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
