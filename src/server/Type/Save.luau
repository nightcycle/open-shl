--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
-- Modules
-- Components
-- Hooks
-- Types
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local EconomyType = require("@game/ReplicatedStorage/Shared/Type/Economy")
local GameType = require("@game/ReplicatedStorage/Shared/Type/Game")
type Character = CharacterType.Character
type BaseInventory = BaseType.BaseInventory
type BaseLayout = BaseType.BaseLayout
type Balances = EconomyType.Balances
type EntitlementKey = EconomyType.EntitlementKey
type GameId = GameType.GameId

local Types = {}

-- goes up whenever what a game keeps changes shape, along with a migration that takes its saves of the version before
-- there. each game counts its own: a save is only ever read by the game that wrote it, so what one adds is no step
-- for another
Types.SHL2_VERSION = 3
-- no save of it is kept yet. until the game is given its universe its shape is changed in place, without a migration
Types.SHL3_VERSION = 1

-- everything that's kept of a player between visits, it's one document so that it's read + written as a whole
export type PlayerSave = {
	Version: number,
	Game: GameId, -- the game that wrote it. every game keeps its saves under one name, this is what a save says of itself
	Characters: { Character }, -- every slot, in slot order
	ActiveCharacterId: string,
	Balances: Balances,
	Inventory: BaseInventory, -- the furniture + themes the player owns
	Entitlements: { EntitlementKey }, -- only what was handed out for good, a game pass is asked for with every visit
	BaseLayout: BaseLayout,
	IsApartmentLocked: boolean,
	IsTutorialEnabled: boolean,
	LastDailyRewardAt: number, -- unix seconds, 0 until the first one
	PurchaseIds: { string }, -- the receipts that were granted, newest last
	IsLegacyImported: boolean,
}
do -- Types.SHL2PlayerSave, Types.SHL3PlayerSave
	-- a slot is found by its id, so a save where that can't work is as broken as one with a field missing
	local function isLinked(value: PlayerSave): (boolean, string?)
		local isActiveFound = false
		for index, character in value.Characters do
			if character.Id == "" then
				return false, `character {index} has no id`
			end
			for otherIndex = 1, index - 1 do
				if value.Characters[otherIndex].Id == character.Id then
					return false, `characters {otherIndex} + {index} share an id`
				end
			end
			isActiveFound = isActiveFound or character.Id == value.ActiveCharacterId
		end
		if not isActiveFound then
			return false, `no character has the active id`
		end
		return true
	end
	-- the save of one game: a save of another one or of another version doesn't pass for it
	local function newValidator(gameId: GameId, version: number): (value: unknown) -> (boolean, string?)
		local isShape = Type.strictInterface({
			Version = Type.literal(version),
			Game = Type.literal(gameId),
			Characters = Type.array(CharacterType.Character),
			ActiveCharacterId = Type.string,
			Balances = EconomyType.Balances,
			Inventory = BaseType.BaseInventory,
			Entitlements = Type.array(EconomyType.EntitlementKey),
			BaseLayout = BaseType.BaseLayout,
			IsApartmentLocked = Type.boolean,
			IsTutorialEnabled = Type.boolean,
			LastDailyRewardAt = Type.intersection(Type.integer, Type.numberMin(0)),
			PurchaseIds = Type.array(Type.string),
			IsLegacyImported = Type.boolean,
		})
		return Type.intersection(isShape, isLinked)
	end
	Types.SHL2PlayerSave = newValidator("shl2", Types.SHL2_VERSION)
	Types.SHL3PlayerSave = newValidator("shl3", Types.SHL3_VERSION)
end

return Types
