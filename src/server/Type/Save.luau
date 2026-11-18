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
type Character = CharacterType.Character
type BaseInventory = BaseType.BaseInventory
type BaseLayout = BaseType.BaseLayout
type Balances = EconomyType.Balances
type EntitlementKey = EconomyType.EntitlementKey

local Types = {}

-- goes up whenever the shape below changes, along with a migration that takes the saves of the version before it there
Types.CURRENT_VERSION = 2

-- everything that's kept of a player between visits, it's one document so that it's read + written as a whole
export type PlayerSave = {
	Version: number,
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
do -- Types.PlayerSave
	local isShape = Type.strictInterface({
		Version = Type.literal(Types.CURRENT_VERSION),
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
	Types.PlayerSave = Type.intersection(isShape, isLinked)
end

return Types
