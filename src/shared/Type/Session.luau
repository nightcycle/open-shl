--!strict
--!native
-- Services
-- Packages
local Type = require("@game/ReplicatedStorage/Packages/Type")
local TypeUnionLib = require("@game/ReplicatedStorage/Packages/TypeUnionLib")
-- Modules
local PseudoEnum = require("@game/ReplicatedStorage/Generated/PseudoEnum")
-- Components
-- Hooks
-- Types
local AppearanceType = require("@game/ReplicatedStorage/Shared/Type/Character/Identity/Appearance")
local BaseType = require("@game/ReplicatedStorage/Shared/Type/Base")
local CharacterType = require("@game/ReplicatedStorage/Shared/Type/Character")
local QuestType = require("@game/ReplicatedStorage/Shared/Type/Quest")
type Appearance = AppearanceType.Appearance
type Character = CharacterType.Character
type IdentityKey = CharacterType.IdentityKey
type BaseInventory = BaseType.BaseInventory
type BaseLayout = BaseType.BaseLayout
type ResidenceId = BaseType.ResidenceId
type ZoneId = BaseType.ZoneId
type QuestState = QuestType.QuestState

local Types = {}

-- a number a client can't break the maths with, the plain number check lets infinity through
local isFinite = Type.numberConstrainedExclusive(-math.huge, math.huge)

-- what a remote function answers with, the error is always a string a menu can show
export type Result<V> = TypeUnionLib.Result<V, string>

export type Snapshot = {
	Characters: { Character }, -- every slot, in slot order
	ActiveCharacterId: string,
	ActiveIdentityKey: IdentityKey,
	Inventory: BaseInventory?, -- the furniture + themes the player owns, only in a game that has them
	Quest: QuestState?, -- only while a quest is running
}
Types.Snapshot = Type.strictInterface({
	Characters = Type.array(CharacterType.Character),
	ActiveCharacterId = Type.string,
	ActiveIdentityKey = CharacterType.IdentityKey,
	Inventory = Type.optional(BaseType.BaseInventory),
	Quest = Type.optional(QuestType.QuestState),
})

export type FurniturePlacement = {
	FurnitureId: string,
	ZoneId: ZoneId,
	X: number, -- in studs from the middle of the pad
	Z: number,
	RotationDeg: number,
}
Types.FurniturePlacement = Type.strictInterface({
	FurnitureId = Type.string,
	ZoneId = BaseType.ZoneId,
	X = isFinite,
	Z = isFinite,
	RotationDeg = isFinite,
})

export type FurnitureMove = {
	Id: string,
	ZoneId: ZoneId,
	X: number,
	Z: number,
	RotationDeg: number,
}
Types.FurnitureMove = Type.strictInterface({
	Id = Type.string,
	ZoneId = BaseType.ZoneId,
	X = isFinite,
	Z = isFinite,
	RotationDeg = isFinite,
})

-- everything a client builds a residence from, the server only hands it to somebody who may walk in
export type ResidenceState = {
	ResidenceId: ResidenceId,
	OwnerUserId: number,
	Layout: BaseLayout,
	Costumes: { [string]: Appearance }, -- what the suit displays wear, keyed by the character id they hold
}
Types.ResidenceState = Type.strictInterface({
	ResidenceId = BaseType.ResidenceId,
	OwnerUserId = Type.integer,
	Layout = BaseType.BaseLayout,
	Costumes = Type.map(Type.string, AppearanceType.Appearance),
})

export type DailyReward = {
	Currency: PseudoEnum.Currency,
	Amount: number,
}
Types.DailyReward = Type.strictInterface({
	Currency = Type.literal(table.unpack(PseudoEnum.getEnumItems("Currency"))),
	Amount = Type.intersection(Type.integer, Type.numberPositive),
})

return Types
